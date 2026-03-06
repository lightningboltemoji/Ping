# Ping.app

Reads what **items in your dock have a red badge** and **makes it more obvious**. 

Below shows the Messages app configured to glow green and the Mail app to glow blue.

<img width="600" alt="Video of the plugin clearing an unsent message from the chatbox" src="/.github/preview.webp"/>

## Configuration

Apps must be configured before they'll be highlighted by Ping. For each app, you can set:

- What color is displayed (optionally can be different numeric and non-numeric badge content)
- What position the glow is from (top, bottom, left, right)
- How intense the glow is

## Aspirations

- Improve packaging and distribution (e.g. Homebrew)
- Additional visual customizations
- Add effects other than glow

## Building

To build and package:

```
cd bundle
./bundle.sh
# creates => bundle/Ping.app
```

## Motivation

macOS' notification system doesn't work very well for me. With apps like Slack, I sometimes miss notifications because:

1. It's not visually intrusive enough (e.g. light notification against light browser window)
2. It's not persistent, so I'll notice it initially but forget to revisit

Previously, I used [SketchyBar](https://github.com/FelixKratz/SketchyBar) to put Slack notifications in my menu bar. This is a great setup, but moving away from the default menu bar causes other inconveniences for my workflow, so I wanted a solution that wasn't so drastic.
