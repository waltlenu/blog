+++
draft = false
title = "Hugo"
date = "2018-12-30T17:06:51Z"
description = "preview a hugo site"
slug = ""
tags = ["hugo"]
categories = ["blog"]
externalLink = ""
series = []
+++
Building this site with [Hugo](https://gohugo.io), because it's a static blog generator and it's very fast.

Preview the site locally, including drafted, expired and future content:

```bash
hugo server -D -E -F --disableFastRender --cleanDestinationDir
```

Add theme:

```bash
git submodule add https://github.com/luizdepra/hugo-coder.git themes/coder
```
