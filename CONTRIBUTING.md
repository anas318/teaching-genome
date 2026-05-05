# Contributing to Teaching Genome 🧬📚

First off, thank you for considering contributing to Teaching Genome! It's people like you that make Teaching Genome such a great tool for educators worldwide.

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](./CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

---

## How Can I Contribute?

### Reporting Bugs 🐛

Before creating bug reports, please check the [issue list](https://github.com/anasaleryani/teaching-genome/issues) as you might find out that you don't need to create one.

**When creating a bug report, please include:**
- **Clear title and description**
- **Steps to reproduce** the problem
- **Expected behavior** vs actual behavior
- **Screenshots or recordings** if applicable
- **Your environment**: OS, Node version, npm version
- **Browser** (if frontend issue)

### Suggesting Features 🚀

Feature suggestions are tracked as GitHub [Issues](https://github.com/anasaleryani/teaching-genome/issues).

**When suggesting a feature, include:**
- **Clear use case** - why do you need this?
- **Proposed solution** or design mockup
- **Alternatives considered**
- **Who benefits** - students? teachers? institutions?

### Pull Requests 📝

**To submit a Pull Request:**

1. **Fork** the repository
2. **Create a feature branch**:
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Make your changes**
   - Follow the code style (see below)
   - Add tests if applicable
   - Update documentation if needed
4. **Commit your changes**:
   ```bash
   git commit -m "Add amazing feature"
   ```
5. **Push to your fork**:
   ```bash
   git push origin feature/amazing-feature
   ```
6. **Open a Pull Request** with a clear description

---

## Development Setup

### Prerequisites
- Node.js 18+
- npm or yarn
- Git
- A code editor (VS Code recommended)

### Getting Started

1. **Clone your fork**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/teaching-genome.git
   cd teaching-genome
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Create `.env.local`**:
   ```bash
   cp .env.example .env.local
   ```

4. **Add your credentials** (get free tier from Supabase, Gemini)

5. **Start development server**:
   ```bash
   npm run dev
   ```

6. **Open http://localhost:3000**

### Project Structure

```
teaching-genome/
├── frontend/
│   ├── app/                    # Next.js app router
│   │   ├── page.tsx           # Landing page
│   │   ├── layout.tsx         # Root layout
│   │   ├── upload-course/     # Course creation
│   │   ├── course/            # Course dashboard
│   │   │   ├── [id]/
│   │   │   │   ├── page.tsx   # Course overview
│   │   │   │   └── week/      # Week details & PDF download
│   │   ├── dashboard/         # User dashboard
│   │   └── login/             # Authentication
│   ├── components/            # Reusable React components
│   │   ├── Toast.tsx
│   │   ├── ProgressBar.tsx
│   │   └── Skeleton.tsx
│   ├── lib/                   # Utilities
│   │   └── supabase.ts
│   ├── public/                # Static assets
│   │   └── logo.png
│   └── styles/                # CSS
├── docs/                      # Documentation
│   ├── SETUP.md
│   ├── ARCHITECTURE.md
│   ├── API.md
│   └── DEPLOYMENT.md
├── LICENSE
├── README.md
└── .env.example
```

---

## Code Style & Standards

### TypeScript
- Use **strict mode** enabled
- Type all function parameters and returns
- Avoid `any` type

```typescript
// ✅ Good
function greetTeacher(name: string): string {
  return `Hello, ${name}!`;
}

// ❌ Avoid
function greetTeacher(name: any) {
  return `Hello, ${name}!`;
}
```

### React Components
- Use **functional components** with hooks
- Use **const** for components
- One component per file
- Descriptive component names

```typescript
// ✅ Good
const CourseCard = ({ course }: CourseCardProps) => {
  return <div>{course.name}</div>;
};

// ❌ Avoid
const c = (props: any) => {
  return <div>{props.c}</div>;
};
```

### Naming Conventions
- **Components**: PascalCase (`CourseCard`, `WeekDetails`)
- **Files**: kebab-case (`course-card.tsx`)
- **Functions**: camelCase (`fetchCourses()`)
- **Constants**: UPPER_SNAKE_CASE (`MAX_WEEKS = 14`)
- **Types/Interfaces**: PascalCase (`CourseData`, `WeekProps`)

### Tailwind CSS
- Use utility classes (don't create custom CSS)
- Follow mobile-first design
- Use semantic color naming

```jsx
// ✅ Good
<div className="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition">
  
// ❌ Avoid
<div style={{backgroundColor: 'white', borderRadius: '8px', padding: '24px'}}>
```

---

## Testing

### Running Tests
```bash
npm test              # Run all tests
npm test -- --watch  # Watch mode
npm test -- --coverage  # Coverage report
```

### Writing Tests
- Use Jest & React Testing Library
- Test behavior, not implementation
- Aim for > 80% coverage on new code

```typescript
// ✅ Good test
test('CourseCard renders course name', () => {
  const course = { id: '1', name: 'AI 101' };
  const { getByText } = render(<CourseCard course={course} />);
  expect(getByText('AI 101')).toBeInTheDocument();
});
```

---

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code style (no logic change)
- `refactor`: Code refactor
- `test`: Add/update tests
- `chore`: Dependencies, build, etc.

**Examples:**
```bash
git commit -m "feat(pdf): add chapter support to PDF generation"
git commit -m "fix(upload): handle large PDF files correctly"
git commit -m "docs: update setup guide with Supabase credentials"
```

---

## Git Workflow

1. **Create feature branch** from `main`:
   ```bash
   git checkout -b feature/descriptive-name
   ```

2. **Keep branch up-to-date**:
   ```bash
   git fetch origin
   git rebase origin/main
   ```

3. **Commit regularly**:
   ```bash
   git commit -m "feat: specific change"
   ```

4. **Push before PR**:
   ```bash
   git push origin feature/descriptive-name
   ```

---

## Pull Request Guidelines

### Before Submitting
- ✅ Test your changes locally
- ✅ Update documentation if needed
- ✅ Add/update tests
- ✅ Follow code style
- ✅ No console errors or warnings
- ✅ Rebase on latest main

### PR Title Format
```
[type]: Brief description (max 50 chars)

Examples:
- [feat]: Add dark mode support
- [fix]: Correct PDF week number display
- [docs]: Update deployment guide
```

### PR Description Template
```markdown
## Description
Brief explanation of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## How to Test
1. Step 1
2. Step 2

## Screenshots (if applicable)
[Add screenshots]

## Checklist
- [ ] Code follows style guidelines
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No new warnings generated
```

---

## Documentation

### Writing Docs
- Use **Markdown** format
- Clear, concise language
- Include code examples
- Link to related docs

### Where to Document
- **README.md**: Project overview
- **docs/SETUP.md**: Installation & setup
- **docs/ARCHITECTURE.md**: How it works
- **docs/DEPLOYMENT.md**: Deployment guide
- **Code comments**: Complex logic only

---

## Good First Issues 🌟

Looking to start contributing? Pick one of these:

- **[Add dark mode](https://github.com/anasaleryani/teaching-genome/issues)** - Frontend CSS
- **[Improve error messages](https://github.com/anasaleryani/teaching-genome/issues)** - UX improvement
- **[Add keyboard shortcuts](https://github.com/anasaleryani/teaching-genome/issues)** - Accessibility
- **[Create user guide](https://github.com/anasaleryani/teaching-genome/issues)** - Documentation
- **[Add Spanish translations](https://github.com/anasaleryani/teaching-genome/issues)** - i18n

---

## Questions?

- **Discord**: Join our [community server](https://discord.gg/teaching-genome)
- **GitHub Discussions**: [Ask a question](https://github.com/anasaleryani/teaching-genome/discussions)
- **Email**: contributors@teachinggenome.dev

---

## Recognition

Contributors will be:
- Added to [CONTRIBUTORS.md](./CONTRIBUTORS.md)
- Mentioned in release notes
- Featured in our newsletter
- Given recognition on our website

---

## License

By contributing, you agree that your contributions will be licensed under its MIT License.

---

<div align="center">

**Thank you for making Teaching Genome better! 🎓**

</div>
