# Writing an Angular+Markdown Blogging Framework. Part 1 of ?

By Ben on 2022-01-17

## Introduction

Many years ago, when the web was young, blogging was the de facto way to share your thoughts and experiences. 3rd party blogging providers were an easy way to let the world hear your voice. One of the most common projects to learn a new language or web framework was to create and host your own blogging solution.

Over the years I've created blogs using the [LAMP stack](<https://en.wikipedia.org/wiki/LAMP_(software_bundle)>), [django](https://www.djangoproject.com/), the [MEAN stack](<https://en.wikipedia.org/wiki/MEAN_(solution_stack)>), and many other frameworks that I've long since forgotten. (If I remember them, I'll be sure to come back and update this.) Eventually, I no longer had any time to keep up with the ever changing landscape and maintain what I had built, worrying about SEO and making sure I could be googled, looking at who was visiting and what. My personal site slowly stopped getting updates and eventually just became a static HTML page.

For a while, I've wanted to blow the dust off of my site and get back into writing my thoughts down. Primarily, so I have a place I can look when I'm trying to recall how I solved a particular problem or situation. But if someone else can find value in my thoughts, then doubly worth sharing them.

Living within the moment now, I don't plan on chasing the shiniest object I can find. I want to keep it simple and use what I know. And maybe I'll pick up on a few things along the way.

My plan is to use Angular, Nrwl's nx framework, and Markdown to write the content. These are tools I use day in and out for my job. Nothing too fancy. All the source code is available on [github](https://github.com/bstruthers/nx-weblog). As I create the framework, I'll also be writing about things as I go. Dog fooding my blog... or blog fooding for a really lame dad joke.

It won't be perfect, it won't have all the bells and whistles that can be found elsewhere. But it's mine and a start of me sharing my thoughts again to whoever might be reading.

## Getting started

I'm using [nx](https://nx.dev/) to for my project. I won't go into reasons why to us nx, those can be found elsewhere. Not that I expect to need everything that nx can provide, but who knows where things will go. And again, it's what I know.

nx will add a few default items that need to be cleaned up, like a welcome component. Once the slate is clean, its time to start laying the foundation for the framework.

### Setting the title

In order for it to be a blogging framework, it'll need some sort of configuration options. The first one will drive the title. I chose to use YAML for storing the configuration and created a config file under the assets folder.

```yaml
# config.yaml

title: '<YOUR TITLE HERE>' # Update the index.html <title> tag to match
```

When the app is initialized, it'll make a HTTP request to get the config file, parse it using the [npm YAML library](https://www.npmjs.com/package/yaml), and use the Angular `Title` service to set the blog's title. When entries are rendered, the same service will be used to update the title to include the entry's title.

```typescript
// app.component.ts

ngOnInit(): void {
  this.http.get('/assets/config.yaml', {
    responseType: 'text'
  }).subscribe(response => {
    const parsed = YAML.parse(response);
    this.titleService.setTitle(parsed.title);
  });
}
```

An improvement would be to parse the config files contents into a strongly typed structure, but I'm keeping it simple. 😀

Quick test and we're good to go.

```typescript
// app.component.spec.ts

it('should pull the configuration file and set the title on init', () => {
  const titleService = TestBed.inject(Title);
  jest.spyOn(titleService, 'setTitle');

  const httpRequest = httpMock.expectOne('/assets/config.yaml');
  httpRequest.flush('title: Hello, there');
  httpMock.verify();

  expect(titleService.setTitle).toHaveBeenCalledWith('Hello, there');
});
```

### Storing posts

The plan is to store posts under the assets, similar to the config file. Since I don't want my blog fooded posts to end up in the repository of the framework code, the .gitignore has been updated to ... ignore them.

```yaml
# .gitignore

# Blog stuff
apps/blog/src/assets/contents/posts/
```

### E2E

The last thing to wrap up, fixing up the E2E tests. nx adds a Cypress test project by default, with some tests looking for the defaults. The defaults are removed and in their place a test asserting the title has been set. Right now this is basically a duplication of the unit tests in the app, but the Cypress tests will be important later and I wanted to make sure things were ready to go.

```typescript
// app.spec.ts

describe('blog', () => {
  beforeEach(() => {
    cy.intercept('/assets/config.yaml', 'title: Hello, there!').as('config');
    cy.visit('/');
  });

  it('should have the title from the configuration', () => {
    cy.title().should('eq', 'Hello, there!');
  });
});
```

## Calling it a day

At this point, the app is created, I've started a blog entry about what was done, and have some basic functionality with tests. A good stopping point before jumping into the next part!
