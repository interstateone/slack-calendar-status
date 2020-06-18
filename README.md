# slack-calendar-status

Updates your Slack status based on events in Calendar.app. Installs its own launch agent so it runs in the background periodically.

Requires a Slack token with permission to set your status. Set it as a SLACK_TOKEN environment variable. A legacy token is deprecated but the easiest way to do this: https://api.slack.com/custom-integrations/legacy-tokens

You can specify a specific calendar to use with the CALENDAR environment variable.

```
# First build the binary and package it into an app bundle
make

# Then run it once with the appropriate environment variables to install the launch agent and run it the first time
CALENDAR=some-calendar-name@example.com \
SLACK_TOKEN=xoxp-0000000000 \
./slack-calendar-status.app/Contents/MacOS/slack-calendar-status
```

---

This was originally implemented with [swift-sh](https://github.com/mxcl/swift-sh) as a single Swift file. A change in Catalina to the way that launchctl and tccd interact to launch executables broke this, and the only way I've gotten this to work again in a similar way is to package it into an app bundle.
