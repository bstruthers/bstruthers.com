# Writing an Angular+Markdown Blogging Framework. Part 2 of 4

By Ben on 02/19/2022

## Introduction

Every blog needs a couple basic pages and structure. Since the blog entries are going to be done in Markdown, the framework might as well use Markdown for everything. Since the pages are core to the framework, they can't be ignored by git and need to be committed.

## Adding more content

Under the assets folder, I created three additional Markdown files for the most essential pages `home.md`, `about.md`, and `not-found.md`. The content in home.md is the home page, the content in about.md is a little bio for any visitors, and not-found.md will be the 404 page.

A blog also needs a header, footer, content, and sidebar areas. The content area will be populated with the blog entries, home, and about content. The rest of the areas will need Markdown for their content. I created three more files, `header.md`, `sidebar.md`, and `footer.md`.

## Rendering the structure

At this point, there's a bunch of Markdown files but the blog is still an empty canvas. Time to add some structure.

### HTML markup for the Markdown

Since the app component is the root of everything and I'm keeping it simple, I defined the header, content, sidebar, and footer sections. For ease of styling / extensibility each element has a corresponding class added.

```html
<!--app.component.html-->

<header class="blog-header"></header>

<main class="blog-content"></main>

<aside class="blog-sidebar"></aside>

<footer class="blog-footer"></footer>
```

The app component will also need to fetch the header, sidebar, and footer content. I updated the initialization to fetch the additional resources.

```typescript
// app.component.ts

header = '';
sidebar = '';
footer = '';

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

ngOnInit(): void {
  combineLatest([
      this.http.get('/assets/config.yaml', { responseType: 'text' }),
      this.http.get('/assets/header.md', { responseType: 'text' }),
      this.http.get('/assets/sidebar.md', { responseType: 'text' }),
      this.http.get('/assets/footer.md', { responseType: 'text' }),
    ]) .subscribe(([config, header, sidebar, footer]) => {
      const parsed = YAML.parse(config);
      this.titleService.setTitle(parsed.title);

      this.header = header;
      this.sidebar = sidebar;
      this.footer = footer;
    });
}
```

and updated the tests.

```typescript
// app.component.spec.ts

it('should request the configuration file and structural content, and set the title and content on init', () => {
  const titleService = TestBed.inject(Title);
  jest.spyOn(titleService, 'setTitle');

  const configRequest = httpMock.expectOne('/assets/config.yaml');
  configRequest.flush('title: Hello, there');

  const headerRequest = httpMock.expectOne('/assets/header.md');
  headerRequest.flush('# header.md');

  const sidebareRequest = httpMock.expectOne('/assets/sidebar.md');
  sidebareRequest.flush('# sidebar.md');

  const footerRequest = httpMock.expectOne('/assets/footer.md');
  footerRequest.flush('# footer.md');

  httpMock.verify();

  expect(titleService.setTitle).toHaveBeenCalledWith('Hello, there');
  expect(component.header).toBe('# header.md');
  expect(component.sidebar).toBe('# sidebar.md');
  expect(component.footer).toBe('# footer.md');
});
```

### Using ngx-markdown for rendering

To render all the Markdown, I added the [ngx-markdown](https://github.com/jfcere/ngx-markdown) library to the framework and configured it for my needs. With the Markdown renderer ready and the Markdown content retrieved, it was time to combine them.

```html
<!--app.component.html-->

<header class="blog-header">
  <markdown [data]="header"> </markdown>
</header>

<main class="blog-content"></main>

<aside class="blog-sidebar">
  <markdown [data]="sidebar"> </markdown>
</aside>

<footer class="blog-footer">
  <markdown [data]="footer"> </markdown>
</footer>
```

### Conditioning

If the there's no content for the header, sidebar, or footer, I didn't want to render those elements as empty. So I conditioned the display. If there's no header, the title from the configuration file will be used. Otherwise the other areas will not render.

```html
<!--app.component.html-->

<header class="blog-header">
  <ng-container *ngIf="header; else defaultHeaderTemplate">
    <markdown [data]="header"> </markdown>
  </ng-container>
  <ng-template #defaultHeaderTemplate>
    <h1>{{ title }}</h1>
  </ng-template>
</header>

<main class="blog-content"></main>

<aside class="blog-sidebar" *ngIf="sidebar">
  <markdown [data]="sidebar"> </markdown>
</aside>

<footer class="blog-footer" *ngIf="footer">
  <markdown [data]="footer"> </markdown>
</footer>
```

```typescript
// app.component.ts

title = '';

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

ngOnInit(): void {
  combineLatest([
      this.http.get('/assets/config.yaml', { responseType: 'text' }),
      this.http.get('/assets/header.md', { responseType: 'text' }),
      this.http.get('/assets/sidebar.md', { responseType: 'text' }),
      this.http.get('/assets/footer.md', { responseType: 'text' }),
    ]) .subscribe(([config, header, sidebar, footer]) => {
      const parsed = YAML.parse(config);
      this.title = parsed.title;
      this.titleService.setTitle(this.title);

      // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    });
}
```

```typescript
// app.component.spec.ts

it('should request the configuration file and structural content, and set the title and content on init', () => {
  const titleService = TestBed.inject(Title);
  jest.spyOn(titleService, 'setTitle');

  const configRequest = httpMock.expectOne('/assets/config.yaml');
  configRequest.flush('title: Hello, there');

  const headerRequest = httpMock.expectOne('/assets/header.md');
  headerRequest.flush('# header.md');

  const sidebareRequest = httpMock.expectOne('/assets/sidebar.md');
  sidebareRequest.flush('# sidebar.md');

  const footerRequest = httpMock.expectOne('/assets/footer.md');
  footerRequest.flush('# footer.md');

  httpMock.verify();

  expect(component.title).toBe('Hello, there');
  expect(titleService.setTitle).toHaveBeenCalledWith('Hello, there');
  expect(component.header).toBe('# header.md');
  expect(component.sidebar).toBe('# sidebar.md');
  expect(component.footer).toBe('# footer.md');
});
```

## Rendering the content

### Content component

With the structure rendered, its time to add the content. For that I'll use Angular's routing framework. Routing will need a component to render the content, so I created a new component called ... content. The content component will use the route's data property to control what file needs to be rendered.

```typescript
// content.component.ts

ngOnInit(): void {
  this.route.data.pipe(
  switchMap((d: Data) => {
    return this.http.get(`/assets/${d['content']}.md`, { responseType: 'text' });
  }),
    takeUntil(this.unsubscribe$)
).subscribe(content => {
  this.content = content;
});
}
```

```html
<!-- content.component.html -->

<markdown [data]="content"> </markdown>
```

```typescript
// content.component.spec.ts

describe('ContentComponent', () => {
  let fixture: ComponentFixture<ContentComponent>;
  let component: ContentComponent;
  let httpMock: HttpTestingController;

  let dataSubject$ = new BehaviorSubject<Data>({ content: 'content-file' });

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [HttpClientTestingModule, MarkdownModule.forRoot()],
      declarations: [ContentComponent],
      providers: [
        {
          provide: ActivatedRoute,
          useValue: {
            data: dataSubject$.asObservable(),
          },
        },
      ],
    }).compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(ContentComponent);
    component = fixture.componentInstance;
    httpMock = TestBed.inject(HttpTestingController);

    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should pull the content from the route to determine which content to render', () => {
    const contentRequest = httpMock.expectOne('/assets/content-file.md');
    contentRequest.flush('# content.md');

    httpMock.verify();

    expect(component.content).toBe('# content.md');
  });
});
```

### Routing

With the content component created, routes are defined for home, about, and the not-found content.

```typescript
RouterModule.forRoot([
  { path: '', component: ContentComponent, data: { content: 'home' } },
  { path: 'about', component: ContentComponent, data: { content: 'about' } },
  { path: '**', component: ContentComponent, data: { content: 'not-found' } },
]);
```

And the app component updated to output the route.

```html
<-- app.component.html-->

<main class="blog-content">
  <router-outlet></router-outlet>
</main>
```

After that, the home page, about page, and not found should be rendering.

## E2E

With everything rendering, I added some additional Cypress tests to ensure everything continues to work as intended.

```typescript
// app.spec.ts

describe('When rendering the blog', () => {
  beforeEach(() => {
    cy.intercept('/assets/header.md', '# header.md').as('header');
    cy.intercept('/assets/sidebar.md', '# sidebar.md').as('sidebar');
    cy.intercept('/assets/footer.md', '# footer.md').as('footer');
    cy.intercept('/assets/home.md', '# content.md').as('content');
    cy.intercept('/assets/config.yaml', 'title: Hello, there!').as('config');
    cy.visit('/');
  });

  it('should have the title from the configuration', () => {
    cy.title().should('eq', 'Hello, there!');
  });

  it('should have a header, content, sidebar, and footer', () => {
    cy.get('.blog-header').should('exist').should('contain.text', 'header.md');
    cy.get('.blog-content')
      .should('exist')
      .should('contain.text', 'content.md');
    cy.get('.blog-sidebar')
      .should('exist')
      .should('contain.text', 'sidebar.md');
    cy.get('.blog-footer').should('exist').should('contain.text', 'footer.md');
  });

  it('should use the title for the header there is no content', () => {
    cy.intercept('/assets/header.md', '').as('header');
    cy.visit('/');

    cy.get('.blog-header')
      .should('exist')
      .should('contain.text', 'Hello, there!');
  });

  it('should not show a sidebar when there is no content', () => {
    cy.intercept('/assets/sidebar.md', '').as('sidebar');
    cy.visit('/');

    cy.get('.blog-sidebar').should('not.exist');
  });

  it('should not show a footer when there is no content', () => {
    cy.intercept('/assets/footer.md', '').as('footer');
    cy.visit('/');

    cy.get('.blog-footer').should('not.exist');
  });
});
```

```typescript
// about.spec.ts

describe('When rendering the about page', () => {
  beforeEach(() => {
    cy.intercept('/assets/header.md', '# header.md').as('header');
    cy.intercept('/assets/sidebar.md', '# sidebar.md').as('sidebar');
    cy.intercept('/assets/footer.md', '# footer.md').as('footer');
    cy.intercept('/assets/about.md', '# about page.md').as('content');
    cy.intercept('/assets/config.yaml', 'title: Hello, there!').as('config');
    cy.visit('/about');
  });

  it('should show the about page content', () => {
    cy.get('.blog-content')
      .should('exist')
      .should('contain.text', 'about page.md');
  });
});
```

```typescript
// home.spec.ts

describe('When rendering the home page', () => {
  beforeEach(() => {
    cy.intercept('/assets/header.md', '# header.md').as('header');
    cy.intercept('/assets/sidebar.md', '# sidebar.md').as('sidebar');
    cy.intercept('/assets/footer.md', '# footer.md').as('footer');
    cy.intercept('/assets/home.md', '# home page.md').as('content');
    cy.intercept('/assets/config.yaml', 'title: Hello, there!').as('config');
    cy.visit('/');
  });

  it('should show the home page content', () => {
    cy.get('.blog-content')
      .should('exist')
      .should('contain.text', 'home page.md');
  });
});
```

```typescript
// not-found.spec.ts

describe('When rendering the Not Found page', () => {
  beforeEach(() => {
    cy.intercept('/assets/header.md', '# header.md').as('header');
    cy.intercept('/assets/sidebar.md', '# sidebar.md').as('sidebar');
    cy.intercept('/assets/footer.md', '# footer.md').as('footer');
    cy.intercept('/assets/not-found.md', '# not-found page.md').as('content');
    cy.intercept('/assets/config.yaml', 'title: Hello, there!').as('config');
    cy.visit('/asdfadgfas');
  });

  it('should show the not found page content', () => {
    cy.get('.blog-content')
      .should('exist')
      .should('contain.text', 'not-found page.md');
  });
});
```

## Wrapping it up for now

At this point, the basic structure and content pages are rendering. Time to take a break. Up next, rendering entries.
