# Glug

Glug is a haskell-based CLI and Javascript API for for making word-finding games from movies.

## Usage

`glug.exe [--cli | --api]`

For full API support save your api key for [The Movie Database](https://www.themoviedb.org/) to
the environment variable `TMDB_KEY`.

The web server listens on port `3000`.

## Installation

Install [Haskell Stack](http://docs.haskellstack.org/en/stable/README/).

`> stack setup`

`> stack [build | test]`

Execute your stack binary:

`> stack exec glug-exe -- [--cli | --api]`

## API

### GET `/titles/{title}`

Searches for the given title name and returns possible candidates. Please urlencode the title.

```json
[
  {
    "href": "/subtitles/finding-nemo",
    "title": "Finding Nemo",
    "subs": 194
  }
]
```

### GET `/words/{href}`

Gets interesting words from the chosen movie. Based on the path to the movie found in `/titles/{title}`.

```json
{
  "imdbid": "tt0266543",
  "runtime": 6000,
  "ranked_words": [
    {
      "word": "foo",
      "occurances": [100, 4500, 5664]
    }
  ]
}
```

### GET `/movie/{imdbid}`

Gets a handful of information about the given movie from [The Movie Database](https://www.themoviedb.org/).

```json
{
  "runtime": 6000,
  "poster":  "/zjqInUwldOBa0q07fOyohYCWxWX.jpg",
  "overview": "A tale which follows the comedic and eventful journeys of two fish, the fretful ..."
}
```
