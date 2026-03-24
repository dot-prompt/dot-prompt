# Implementation Plan: dot-prompt Documentation Website

## Overview

Create a comprehensive documentation website for .prompt — a compiled language for LLM prompts. The site will serve as the primary resource for developers learning and using the language, covering language reference, use cases, philosophy, and providing excellent SEO performance.

## Requirements

### Content Requirements

1. **Language Documentation**
   - Complete syntax reference for all .prompt constructs
   - Type system documentation (str, int, bool, enum, list)
   - Control flow documentation (if/elif/else, case, vary)
   - Fragment system (static, dynamic, collections)
   - Response contract syntax
   - Versioning system

2. **"Why" Section**
   - Problem statement (prompt management challenges)
   - How .prompt solves these problems
   - Comparison with alternatives (f-strings, YAML, markdown)
   - Benefits of compile-time resolution

3. **Use Cases**
   - Educational/teacher prompts
   - Multi-step workflows
   - Conditional response generation
   - Fragment composition patterns
   - Version-controlled prompt APIs

4. **SEO Requirements**
   - Semantic HTML structure
   - Meta tags and Open Graph
   - Sitemap generation
   - Structured data (JSON-LD)
   - Fast page load times
   - Mobile responsive
   - Clean URLs

### Technical Requirements

1. **Static Site Generation** — Build from markdown/content files
2. **Documentation Features**
   - Syntax highlighting for .prompt code
   - Version navigation
   - Search functionality
   - Code copy buttons
   - Dark/light theme
3. **Performance** — Fast loading, minimal JavaScript

---

## Architecture Changes

### New Files Structure

```
website/
├── content/
│   ├── docs/
│   │   ├── getting-started.md
│   │   ├── language-reference.md
│   │   ├── types.md
│   │   ├── control-flow.md
│   │   ├── fragments.md
│   │   ├── response-contracts.md
│   │   ├── versioning.md
│   │   └── api-reference.md
│   ├── why/
│   │   ├── the-problem.md
│   │   ├── the-solution.md
│   │   └── comparison.md
│   └── use-cases/
│       ├── index.md
│       ├── educational-prompts.md
│       ├── multi-step-workflows.md
│       ├── conditional-generation.md
│       └── fragment-composition.md
├── src/
│   ├── pages/
│   │   ├── index.astro
│   │   ├── docs/[...slug].astro
│   │   ├── why/[...slug].astro
│   │   └── use-cases/[...slug].astro
│   ├── components/
│   │   ├── Header.astro
│   │   ├── Sidebar.astro
│   │   ├── CodeBlock.astro
│   │   ├── ThemeToggle.astro
│   │   └── Search.astro
│   ├── layouts/
│   │   ├── DocsLayout.astro
│   │   └── MarketingLayout.astro
│   └── styles/
│       └── global.css
├── public/
│   ├── sitemap.xml
│   ├── robots.txt
│   └── opengraph/
├── astro.config.mjs
├── tailwind.config.mjs
└── package.json
```

### Integration with Existing Codebase

- Add `website/` folder at root level
- Create scripts to generate SEO metadata from .prompt examples
- Link from existing Readme.md to new website

---

## Implementation Steps

### Phase 1: Project Setup & Foundation

1. **Initialize Astro project** (File: website/astro.config.mjs)
   - Install Astro with Tailwind integration
   - Configure markdown/MDX support
   - Set up sitemap generation
   - Configure build output for static site

2. **Create base layouts** (File: website/src/layouts/*.astro)
   - MarketingLayout for landing/why/use-cases
   - DocsLayout for language reference
   - Shared header/footer components
   - Responsive navigation

3. **Set up styling system** (File: website/src/styles/global.css)
   - CSS custom properties for theming
   - Typography scale
   - Code block styling
   - Light/dark theme colors

### Phase 2: Core Content Pages

4. **Build landing page** (File: website/src/pages/index.astro)
   - Hero section with value proposition
   - Quick example code block
   - Feature highlights
   - Call-to-action buttons
   - SEO meta tags

5. **Create "Why" section** (File: website/content/why/*.md)
   - "The Problem" page: scattered prompts, no versioning, token waste
   - "The Solution" page: compile-time resolution benefits
   - "Comparison" page: vs f-strings, YAML, markdown templates

6. **Build "Use Cases" section** (File: website/content/use-cases/*.md)
   - Index page with case study cards
   - 5 detailed use case pages with code examples

### Phase 3: Documentation Pages

7. **Create language reference** (File: website/content/docs/*.md)
   - Getting Started guide
   - Complete language reference
   - Types documentation
   - Control flow (if/elif/else, case, vary)
   - Fragments (static, dynamic, collections)
   - Response contracts
   - Versioning system

8. **Build interactive code blocks** (File: website/src/components/CodeBlock.astro)
   - Syntax highlighting for .prompt language
   - Copy-to-clipboard functionality
   - Line numbers
   - Tabbed examples (before/after)

### Phase 4: SEO & Performance

9. **Implement SEO system** (File: website/src/components/SEO.astro)
   - Dynamic meta tags per page
   - Open Graph images
   - Twitter Card support
   - JSON-LD structured data
   - Canonical URLs

10. **Generate sitemap & robots** (File: website/public/sitemap.xml)
    - Automatic sitemap from content
    - robots.txt for search engines
    - sitemap-index for large sites

### Phase 5: Search & Navigation

11. **Add search functionality** (File: website/src/components/Search.astro)
    - Client-side search with Fuse.js
    - Index all documentation content
    - Keyboard shortcuts (Cmd+K)

12. **Build sidebar navigation** (File: website/src/components/Sidebar.astro)
    - Auto-generated from content structure
    - Collapsible sections
    - Active state highlighting

### Phase 6: Polish & Deploy

13. **Add theme toggle** (File: website/src/components/ThemeToggle.astro)
    - Dark/light mode support
    - System preference detection
    - Persist preference

14. **Create build & deploy scripts**
    - Netlify/Vercel configuration
    - CI/CD pipeline
    - Preview deployments

---

## Testing Strategy

### Content Testing
- Verify all code examples compile correctly
- Check cross-references between pages
- Validate markdown syntax
- Review for typos and clarity

### SEO Testing
- Validate meta tags with SEO tools
- Test structured data with schema.org validator
- Check sitemap accessibility
- Verify Open Graph preview images

### Performance Testing
- Lighthouse performance score >90
- First Contentful Paint <1.5s
- Time to Interactive <3s
- Mobile responsive on all breakpoints

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Content drift between Readme and website | Use shared code examples in both |
| SEO not optimized for key terms | Research and include relevant keywords |
| Large documentation hard to navigate | Implement robust search and sidebar |
| Code examples become outdated | Add CI check to validate examples |
| Performance issues with many pages | Use Astro's static generation |

---

## Success Criteria

- [ ] Landing page loads in <2 seconds
- [ ] All documentation pages indexed by search engines
- [ ] Core Web Vitals pass (LCP, FID, CLS)
- [ ] Search returns relevant results within 100ms
- [ ] All code examples have syntax highlighting
- [ ] Dark/light theme works without flash
- [ ] Mobile navigation is fully functional
- [ ] Sitemap contains all documentation pages
- [ ] Open Graph previews display correctly
- [ ] JSON-LD validates without errors
