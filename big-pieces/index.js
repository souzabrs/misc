const { performance } = require('perf_hooks');
module.exports = {
	name: 'big-piece',
	label: 'Big Piece',
	pluralLabel: 'Big Pieces',
	extend: 'apostrophe-pieces',
	addFields: [
		{
			name: 'text',
			type: 'string',
			searchable: false
		}
	],
	//eslint-disable-next-line no-unused-vars
	async construct(self, options) {
		const req = self.apos.tasks.getReq();
		const globalDoc = await self.apos.global.findGlobal(req);

		if (!globalDoc.vocabulary) {
			//create a vocabulary to generate random strings
			//its necessary to make queries, after inserting documents
			globalDoc.vocabulary = [...new Array(1000)].map(() => randomWord());

			//also create 50 sample text search queries with 2 words from the
			//100 first ones of vocabulary
			globalDoc.sampleQueries = [];
			for (let i = 0; i != 49; i++) {
				globalDoc.sampleQueries.push(
					[...new Array(2)]
						.map(() => globalDoc.vocabulary[~~(Math.random() * 100)])
						.join(' ')
				);
			}
			await self.apos.global.update(req, globalDoc);
		}

		self.searchCollection = await self.apos.db.collection('search');
		self.on('apostrophe:migrate', 'createIndexes', async () => {
			//create the collection
			await self.searchCollection.insertOne({ _id: 'first' });
			await self.searchCollection.deleteOne({ _id: 'first' });

			//search.t == aposDocs.highSearchText
			self.searchCollection.createIndex({ t: 'text' });

			//search.w == aposDocs.highSearchWords
			self.searchCollection.createIndex({ w: 1 });
		});

		self.insertBigPieces = async () => {
			const vocabulary = globalDoc.vocabulary;

			//how many words to get a ~2MB string?
			//randomWord generates a word of 1 to 15 characters, so 7.5 is the
			//average
			const numWords = ~~((2 * 1024 * 1024) / 7.5);

			//1024 * 2MB ~ 2GB collection
			for (let i = 0; i != 1024; i++) {
				const piece = {};

				//use all words from vocabulary to create the text
				piece.text = [...new Array(numWords)]
					.map(() => vocabulary[~~(Math.random() * 1000)])
					.join(' ');

				//15 words from the first 100 ones
				piece.title = [...new Array(15)]
					.map(() => vocabulary[~~(Math.random() * 100)])
					.join(' ');

				let doc = await self.insert(req, piece);

				//insert a equivalent doc in search collection;
				self.searchCollection.insertOne({
					_id: doc._id,
					w: doc.highSearchWords,
					t: doc.highSearchText
				});
			}
		};

		self.addTask(
			'populate-db',
			'node app big-pieces:populate-db',
			self.insertBigPieces
		);

		self.testDefaultAutocomplete = async () => {
			const queries = globalDoc.sampleQueries;
			const stats = {
				times: [],
				totalTime: 0,
				totalResults: 0
			};
			for (let query of queries) {
				let start = performance.now();
				let docs = await self
					.find(req)
					.autocomplete(query)
					.limit(10)
					.projection({ title: 1, _url: 1 })
					.toArray();
				stats.totalResults += docs.length;
				let time = performance.now() - start;
				stats.times.push(time);
				stats.totalTime += time;
			}
			stats.averageTime = stats.totalTime / queries.length;
			console.log(JSON.stringify(stats, null, 2));
		};

		self.addTask(
			'test-default-autocomplete',
			'node app big-pieces:test-default-autocomplete',
			self.testDefaultAutocomplete
		);

		self.testSeparateCollection = async () => {
			const queries = globalDoc.sampleQueries;
			const stats = {
				times: [],
				totalTime: 0,
				totalResults: 0
			};

			for (let query of queries) {
				let start = performance.now();

				let str = self.apos.utils.sortify(query);
				let words = str.split(/ /);
				let distQuery = words.map(s => ({
					w: self.apos.utils.searchify(s, true)
				}));
				distQuery.push({ t: self.apos.utils.searchify(query) });

				//get distinct words
				let dist = await self.searchCollection.distinct('w', {
					$and: distQuery
				});
				dist = dist.filter(r =>
					words.find(w => r.substring(0, w.length) === w)
				);

				//text search to get the ids
				let ids = await self.searchCollection
					.find(
						{ $text: { $search: dist.join(' ') } },
						{ _id: 1, score: { $meta: 'textScore' } }
					)
					.sort({ score: { $meta: 'textScore' } })
					.limit(10)
					.toArray();

				ids = ids.map(i => i._id);

				//get the related docs
				let results = await self
					.find(req, { _id: { $in: ids } })
					.projection({ _id: 1, title: 1, _url: 1 })
					.sort(false)
					.toArray();

				//sort
				let docs = [];
				for (let r in results) {
					let index = ids.indexOf(results[r]._id);
					docs[index] = results[r];
				}

				stats.totalResults += docs.length;
				let time = performance.now() - start;
				stats.times.push(time);
				stats.totalTime += time;
			}
			stats.averageTime = stats.totalTime / queries.length;
			console.log(JSON.stringify(stats, null, 2));
		};

		self.addTask(
			'test-separate-collection',
			'node app big-pieces:test-separate-collection',
			self.testSeparateCollection
		);

		function randomWord() {
			let word = new Array(1 + ~~(Math.random() * 14));
			for (let i = 0; i != word.length; i++) {
				word[i] = String.fromCharCode(~~(97 + 25 * Math.random()));
			}
			return word.join('');
		}
		//end of construct
	}
};
