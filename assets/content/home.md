# Writing an Angular+Markdown Blogging Framework. Part 1 of 4

By Ben on 02/12/2022

## Introduction

To support my own blog, I created myself (yet) another blogging framework.   The framework is written in Angular, uses Nrwl's nx framework for tooling, and Markdown to write the content.  All the source code is available on [github](https://github.com/bstruthers/nx-weblog). 

## Getting started

The project was initialized using [nx](https://nx.dev/). I won't go into reasons why to use nx or what commands I used, those can be found elsewhere- like the official nx docs. Not that I expect to need everything that nx can provide, but who knows where things will go. And again, it's keeping with what I know.

nx will add a few default items that will need to be cleaned up, like a welcome component. Once the slate is clean, the programming can begin.

### Setting the title

In order for it to be a blogging framework, there needs to be some sort of configuration options.  One such configuration is the overall title. I chose to use YAML for storing the configuration and created a config file under the assets folder.

```yaml
# config.yaml

title: '<YOUR TITLE HERE>' # Update the index.html <title> tag to match
```

When the app is initialized, it'll make a HTTP request to get the config file, parse it using the [npm YAML library](https://www.npmjs.com/package/yaml), and then use the Angular `Title` service to set the blog's title. When entries are rendered, the `Title` service will be used to include the entry's title as the title for the page.

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

Quick test and the changes are good to go.

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

Posts will be stored under the assets, similar to the config file. Since I don't want and mock posts to end up in the repository of the framework code, the .gitignore has been updated to exclude them.

```yaml
# .gitignore

# Blog stuff
apps/blog/src/assets/contents/posts/
```

### E2E

The last thing to wrap up, fixing up the E2E tests. nx adds a Cypress test project by default, with some tests looking for the defaults. The defaults are removed and in their place, a test asserting the title has been set. Right now this is basically a duplication of the unit tests in the app, but the Cypress tests will be important later and I wanted to make sure things were ready to go.

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

## Wrapping up post number one

At this point, the framework has been started and has some basic functionality with tests. A good stopping point before jumping into the next part!