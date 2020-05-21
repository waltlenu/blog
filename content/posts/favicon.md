+++
draft = false
title = "Favicons"
date = "2019-04-07T12:11:50+01:00"
description = "set favicons"
slug = ""
tags = ["favicon"]
categories = ["blog"]
series = []
+++
Back when I was a sysadmin for various web hosting companies I always hated the hundreds of thousands of error log lines complaining about missing favicons:

```text
[Thu Mar 21 14:07:40 2013] [error] [client xxx.xxx.xxx.xxx] File does not exist: /var/www/html/favicon.ico
```

While, yes, you can configure the webserver to ignore those messages, I always wished webmasters|developers|clients would simply add them, even only a 0-byte file:

```bash
> /var/www/html/favicon.ico
```

I don't like generating work for others, so I used a [Favicon Generator](https://realfavicongenerator.net) and placed them in the `/static` subdirectory:

`tree`:

```text
static
├── android-chrome-192x192.png
├── android-chrome-512x512.png
├── apple-touch-icon.png
├── browserconfig.xml
├── favicon-16x16.png
├── favicon-32x32.png
├── favicon.ico
├── mstile-70x70.png
├── mstile-144x144.png
├── mstile-150x150.png
├── mstile-310x150.png
├── mstile-310x310.png
└── site.webmanifest
```

Didn't know there were so many types of them nowadays. And because I don't have a logo yet, I used the original Amiga logo, because, when in doubt, always go Amiga [^1].

![Amiga Logo (1995)](/img/Amiga_Logo_1985.svg 'Amiga Logo 1985')

[^1]: The image above is in the [public domain](https://en.wikipedia.org/wiki/File:Amiga_Logo_1985.svg).
