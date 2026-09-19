# Configuration file for the Sphinx documentation builder.
# -- Project information
project = "atskkserv"
copyright = "2026, Kazuya Takei"
author = "Kazuya Takei"
release = "0.1.0"

# -- General configuration
extensions = [
    # Sphinx bundled extensions
    "sphinx.ext.githubpages",
    "sphinx.ext.todo",
    # My public extensions
    "atsphinx.footnotes",
    # Third party extensions
    "myst_parser",
]
templates_path = ["_templates"]
exclude_patterns = ["_build", "Thumbs.db", ".DS_Store"]
language = "ja"

# -- Options for HTML output
html_theme = "piccolo_theme"
html_static_path = ["_static"]
