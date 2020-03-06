# Conclusions of testing the text search in MongoDB

## 1) The document size in bytes matters

The following query will run fast in collections with many small documents
and slow in collections with many big documents:

```javascript
db.aposDocs.find(
	{ $text: { $search: 'justOneWord' } },
	{ score: { $meta: 'textScore' } }
).sort({
	score: { $meta: 'textScore' }
}).limit(10);
```

Even if the text index is small (e.g. 10 MB) and fits nicely on memory.

In other words, the size of fields not present in the text index matters.

So, if we have a collection with many documents like this:

```javascript
{
	title: 'Short string, with recurring common words',
	data: 'big strings, arrays, embedded documents...',
}
```

E.g.: Each document representing a vehicle and `title` being the its 
description, like 'Green truck, year 2005, with six tires', and `data`
containing anything big, like an array with the names of every person
that have already been inside the vehicle.

We will have many documents with the words 'car', 'truck', 'bus'... in the
title, and some of them will have a big list of people who used it, like
commercial buses.

Creating an index like this:


```javascript
db.aposDocs.createIndex({ title: 'text' });
```

is essential to do text search queries based on the `title` field, but not
enough to have response times of less than one second.

## 2) Smaller documents help a lot

Copying just the fields used to the text search, like this:

```javascript
var docs = db.aposDocs.find(
	{ 
		type: 'vehicle',
		 published: true,
		 trash: false,
		 highSearchText: { $ne: '' }
	},
	{ _id: 1, highSearchText: 1 }
);

while (docs.hasNext()) { 
	let { 
		_id,
		highSearchText,
		lowSearchText,
		searchBoost,
		title,
		highSearchWords
	}  = docs.next();

	db.aposDocs.insertOne({
		type: 'search',
		piece_id: _id,
		slug: 's-' + _id,
		highSearchText,
		highSearchWords,
		lowSearchText,
		searchBoost,
		title,
		//hidden piece
		published: false,
		trash: false
	});
}
```

And creating a partial index like this:

```javascript
db.aposDocs.createIndex({
	highSearchText: 'text',
	lowSearhText: 'text',
	title: 'text',
	searchBoost: 'text'
},{
	partialFilterExpression: {
		type: 'search'
	},
	weights: {
		highSearchText: 4,
		lowSearchText: 1,
		title: 2,
		searchBoost: 8 
	},
	default_language: 'pt'
})
```

Or prefixing with type, like this: 

```javascript
db.aposDocs.createIndex({
	type: 1,
	highSearchText: 'text',
	lowSearhText: 'text',
	title: 'text',
	searchBoost: 'text'
},{
	weights: {
		highSearchText: 4,
		lowSearchText: 1,
		title: 2,
		searchBoost: 8 
	},
	default_language: 'pt'
})
```

**Improve immensely the time response of queries like this:**

```javascript
db.aposDocs.find(
	{
		//Specifying the type is mandatory, now
		type: 'search',
		$text: { $search: 'justOneWord' }
	},
	{ score: { $meta: 'textScore' } }
).sort(
	{ score: { $meta: 'textScore' } }
).limit(10);
```

**
Note #1: without prefixing or partial index is necessary, even there is
an index created as `db.aposDocs.createIndex({ type: 1 })`.

Note #2: copying the search fields to another collection is even better
because is more organized and elegant, but the results are similar.
**

## 3) The driver version doesn't matter

Results are similar, even using the MongoDB shell directly.

## 4) Detailed text index specification doesn't matter

```javascript
db.aposDocs.createIndex({ highSearchText: 'text' });
```

and

```javascript
db.aposDocs.createIndex({ 
	highSearchText: 'text', 
	lowSearchText: 'text',
	title: 'text',
	searchBoost: 'text'
},
{
	weights: {
		highSearchText: 4,
		lowSearchText: 1,
		title: 2,
		searchBoost: 8 
	},
	default_language: 'pt'
});
```

will result in equivalent text search speed. I tested specs one by one.

## 5) Projection and limit() don't help

This:

```javascript
db.aposDocs.find(
		{ $text: { $search: 'justOneWord' } },
		{ _id: 1, score: { $meta: 'textScore' } }
).sort({
	score: { $meta: 'textScore' }
}).limit(1);
```

won't decrease the time response significantly.


## 6) MongoDB version seems to be irrelevant

I tested with docker images of versions `4.0.10-xenial` and `4.2.3-bionic`.

# Suggestion

If the apostrophe-search module used a separate collection to index the
search text fields, it would be:

1. More robust when handling big documents;
1. More easy to design, avoiding concerns about growing data;
1. More scalable;
1. More economic, beacuse this may spare precious server resources.

## How to?

Such implementation would have to be compatible with older versions or
be included on a future version.

The first would require methods that only use the separate collection if
it exists and a command line task to migrate.


