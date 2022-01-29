# Writing an Angular+Markdown Blogging Framework; Part 3 of ?

By Ben on 2022-01-23

## Introduction

With structure and content, next up is rendering blog entries. The content component will also handle those duties.

### Routing

An additional route is added to blog for handling the posts.

```typescript
// app.module.ts

{ path: 'posts/:slug', component: ContentComponent },
```

The "slug" parameter will correspond to the file the framework is to render.

### Updating the content component

Using the "slug" parameter, the content component can make the determination on what to show.

```typescript
// content.component.ts

ngOnInit(): void {
  combineLatest([
    this.route.data,
    this.route.paramMap
  ]).pipe(
  switchMap(([d, p]: [Data, ParamMap]) => {
    let content = d['content'];
    if (p.has('slug')) {
      content = `posts/${p.get('slug')}`
    }

    return this.http.get(`/assets/${content}.md`, { responseType: 'text' });
  }),
    takeUntil(this.unsubscribe$)
).subscribe(content => {
  this.content = content;
  this.changeDetectionRef.detectChanges();
});
}
```

The component should also handle invalid slugs and send the visitor over to the not found page.

```typescript
// content.component.ts

return this.http.get(`/assets/${content}.md`, { responseType: 'text' }).pipe(
  catchError(() => {
    this.router.navigate(['not-found']);
    return '';
  })
);
```

Some updates / additions to the tests to ensure the logic is correct and posts are rendering

```typescript
// content.spec.ts

let dataSubject$ = new BehaviorSubject<Data>({});
let paramsSubject$ = new BehaviorSubject<ParamMap>(convertToParamMap({}));

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

providers: [
  {
    provide: ActivatedRoute,
    useValue: {
      data: dataSubject$.asObservable(),
      paramMap: paramsSubject$.asObservable(),
    },
  },
  {
    provide: Router,
    useValue: {
      navigate: () => {},
    },
  },
];

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

it('should use the slug on the route to determine which content to render', () => {
  paramsSubject$.next(convertToParamMap({ slug: 'slug' }));

  const contentRequest = httpMock.expectOne('/assets/posts/slug.md');
  contentRequest.flush('# slug.md');

  expect(component.content).toBe('# slug.md');
});

it('should redirect to the not found page when there is no content', () => {
  const router = TestBed.inject(Router);
  jest.spyOn(router, 'navigate');
  paramsSubject$.next(convertToParamMap({ slug: 'not-found' }));

  const contentRequest = httpMock.expectOne('/assets/posts/not-found.md');
  contentRequest.flush('', new HttpErrorResponse({ error: 404 }));

  expect(router.navigate).toHaveBeenCalledWith(['not-found']);
});
```

## E2E

Added another Cypress test for the posts.

```typescript
// post.spec.ts

describe('When rendering a post', () => {
  beforeEach(() => {
    cy.intercept('/assets/header.md', '# header.md').as('header');
    cy.intercept('/assets/sidebar.md', '# sidebar.md').as('sidebar');
    cy.intercept('/assets/footer.md', '# footer.md').as('footer');
    cy.intercept('/assets/posts/slug.md', '# slug.md').as('content');
    cy.intercept('/assets/config.yaml', 'title: Hello, there!').as('config');
    cy.visit('/posts/slug');
  });

  it('should show the not found page content', () => {
    cy.get('.blog-content').should('exist').should('contain.text', 'slug.md');
  });

  it('should go to the not found page when the slug does no exist', () => {
    cy.intercept('assets/posts/not-found', { statusCode: 404 });
    cy.visit('/posts/not-found', { failOnStatusCode: false });
    cy.url().should('equal', 'http://localhost:4200/not-found');
  });
});
```
