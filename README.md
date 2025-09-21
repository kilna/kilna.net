# kilna.net

A personal contact and portfolio website built with Hugo, deployed on Cloudflare Pages.

## About

This is the source code for [kilna.net](https://kilna.net), a personal website for Kilna (Anthony Kilna) that serves as a contact hub and project showcase. The site features:

- **Contact Information**: Multiple ways to get in touch including email, phone, messaging apps, and social media
- **Digital Business Cards**: MeCard and vCard formats for easy contact sharing
- **Project Portfolio**: Showcase of various projects and professional work
- **QR Code Integration**: Easy sharing via QR codes
- **Responsive Design**: Mobile-friendly interface

## Tech Stack

- **Static Site Generator**: [Hugo](https://gohugo.io/)
- **Deployment**: [Cloudflare Pages](https://pages.cloudflare.com/)
- **Styling**: Custom CSS with modern design principles
- **Icons**: SVG icons for social media and contact methods
- **Build Tools**: Makefile for development workflow

## Development Setup

### Prerequisites

- [Hugo](https://gohugo.io/installation/) (managed via asdf)
- [asdf](https://asdf-vm.com/) for version management
- [Wrangler CLI](https://developers.cloudflare.com/workers/wrangler/) for Cloudflare deployment
- [direnv](https://direnv.net/) for environment management

### Environment Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/kilna/kilna.net.git
   cd kilna.net
   ```

2. Set up environment variables:
   ```bash
   # Copy and configure environment file
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. Install dependencies:
   ```bash
   # Allow direnv to load environment
   direnv allow
   
   # Install Hugo via asdf
   asdf install
   ```

### Development Commands

```bash
# Start development server
make server

# Build the site
make build

# Deploy to production
make deploy

# Deploy preview to Cloudflare Pages
make preview

# Clean generated files
make clean

# Download/refresh SVG icons
make icons

# Show help
make help
```

## Project Structure

```
kilna.net/
├── content/           # Hugo content files
│   ├── _index.md     # Homepage content
│   ├── projects/     # Project portfolio
│   ├── discord/      # Discord contact info
│   ├── qr/          # QR code pages
│   └── *.md         # Various contact formats
├── layouts/          # Hugo templates
│   ├── _default/     # Default layouts
│   └── _partials/    # Reusable components
├── assets/           # Static assets
│   ├── css/         # Stylesheets
│   ├── js/          # JavaScript
│   └── icons/       # SVG icons
├── scripts/          # Build and deployment scripts
├── public/           # Generated site (gitignored)
├── hugo.yaml        # Hugo configuration
├── wrangler.toml    # Cloudflare Pages configuration
└── Makefile         # Development commands
```

## Features

### Contact Methods
- **Email**: kilna@kilna.com
- **Phone**: +1 (619) 549-8189
- **Messaging**: Telegram, WhatsApp, Signal
- **Social Media**: Facebook, Instagram, Threads, Bluesky, TikTok
- **Professional**: LinkedIn, IMDb, GitHub

### Digital Business Cards
- **MeCard**: `/mecard` - Mobile-friendly contact format
- **vCard**: `/vcard` - Standard vCard format for contacts

### QR Code Integration
- QR codes for easy sharing and contact exchange
- Multiple QR code formats and sizes

## Deployment

The site is automatically deployed to Cloudflare Pages:

- **Production**: `main` branch → https://kilna.net
- **Preview**: Other branches → https://{branch}.kilna.net

### Manual Deployment

```bash
# Deploy to production
make deploy

# Deploy preview
make preview
```

## Configuration

### Hugo Configuration
The main Hugo configuration is in `hugo.yaml`, which includes:
- Site metadata and SEO settings
- Menu definitions for contact and social links
- Custom output formats for MeCard and vCard
- Asset processing and optimization settings

### Cloudflare Pages
Deployment configuration is in `wrangler.toml`:
- Build output directory: `public/`
- Environment-specific settings for production and preview

## Contributing

This is a personal website, but if you find issues or have suggestions:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is open source. See the repository for license details.

## Contact

- **Website**: https://kilna.net
- **Email**: kilna@kilna.com
- **GitHub**: https://github.com/kilna

---

*Built with ❤️ using Hugo and deployed on Cloudflare Pages*
