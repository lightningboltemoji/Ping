# Ping.app <img width="24" alt="Bell icon" src="/Sources/Ping/Resources/Bell.svg"/>

_Makes notifications more obvious with subtle, persistent effects_ 

Works by reading what items in your dock **have a red badge** and **adds screen overlays** to draw attention.

For example, with the Messages app set to glow green, and the Mail app set to glow blue:

<img width="600" alt="Video of the plugin clearing an unsent message from the chatbox" src="/.github/preview.webp"/>

## Configuration

Apps must be configured before they'll be highlighted by Ping. For each app, you can set:

- What color is displayed (optionally, can be different numeric and non-numeric badges)
- What position the glow is from (top, bottom, left, right)
- How intense the glow is

When using the settings UI, changes are written to `~/.config/ping/settings.yaml` for easy backup and portability.

## Aspirations

- Improve packaging and distribution (e.g. Homebrew)
- Additional visual customizations
- Add effects other than glow

## Building

To build and package into Ping.app:

```
./build.sh
```

## Motivation

macOS' notification system doesn't work very well for me. With apps like Slack, I sometimes miss notifications because:

1. It's not visually intrusive enough (e.g. light notification against light browser window)
2. It's not persistent, so I'll notice it initially but forget to revisit

Previously, I used [SketchyBar](https://github.com/FelixKratz/SketchyBar) to put Slack notifications in my menu bar. This is a great setup, but moving away from the default menu bar causes other inconveniences for my workflow, so I wanted a solution that wasn't so drastic.
