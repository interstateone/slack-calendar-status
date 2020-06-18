import Foundation
import EventKit
import PromiseKit
import PMKEventKit
import SlackKit
import LaunchAgent

// MARK: - Extensions and support code

extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }
}

extension DateFormatter {
    static var shortDate: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }
}

extension WebAPI {
    func updateStatus(_ text: String, emoji: String, expiration: Date) -> Promise<Void> {
        return Promise { seal in
            let profile = User.Profile(profile: ["status_text": text,
                                                 "status_emoji": emoji,
                                                 "status_expiration": Int(expiration.timeIntervalSince1970)])
            usersProfileSet(profile: profile, 
                            success: { _ in seal.fulfill(()) },
                            failure: { error in seal.reject(error) })
        }
    }
}

extension EKEvent {
    var isMine: Bool {
        return organizer == nil || (organizer?.isCurrentUser == true)
    }
}

enum Error: Swift.Error {
    case notAuthorized
}

let slackToken = ProcessInfo.processInfo.environment["SLACK_TOKEN"]!
let desiredCalendar = ProcessInfo.processInfo.environment["CALENDAR"]

// MARK: - Launch agent installation

let label = "ca.brandonevans.slack-calendar-status"

if (try? LaunchControl.shared.read(agent: "\(label).plist")) == nil {
    let program = FileManager.default.currentDirectoryPath + "/" + CommandLine.arguments[0]
    let agent = LaunchAgent(label: label, program: program)
    agent.userName = "brandon"
    agent.startInterval = 60
    agent.runAtLoad = true
    agent.standardOutPath = "/Users/brandon/bin/slack-calendar-status.log"
    agent.standardErrorPath = "/Users/brandon/bin/slack-calendar-status.error.log"
    agent.environmentVariables = ["PATH": "/usr/bin:/usr/local/bin",
                                  "SLACK_TOKEN": slackToken]
    if let calendar = desiredCalendar {
        agent.environmentVariables?["CALENDAR"] = calendar
    }

    do {
        try LaunchControl.shared.write(agent)
        try LaunchControl.shared.load(agent)
    }
    catch {
        print("Continuing past LaunchAgent failure: " + String(describing: error))
    }
}

// MARK: - The important bit

let store = EKEventStore()
let slack = WebAPI(token: slackToken)

firstly {
    store.requestAccess(to: .event)
}
.then { (authorization) -> Promise<Void> in
    guard authorization == .authorized else { throw Error.notAuthorized }

    let calendars = store.calendars(for: .event).filter { $0.title == desiredCalendar }
    let predicate = store.predicateForEvents(withStart: Date(), 
                                             end: Date().endOfDay,
                                             calendars: calendars.isEmpty ? nil : calendars)
    let todaysRemainingEvents = store.events(matching: predicate)

    if let pto = todaysRemainingEvents.first(where: { $0.isAllDay && $0.title.contains("PTO") && $0.isMine }) {
        let shortDate = DateFormatter.shortDate.string(from: pto.endDate)
        return slack.updateStatus("PTO until \(shortDate)", 
                                  emoji: ":palm_tree:",
                                  expiration: pto.endDate)
    }
    else if let meeting = todaysRemainingEvents.sorted(by: { $0.startDate < $1.startDate }).first(where: { !$0.isAllDay && $0.availability != .free && $0.startDate < Date() && $0.endDate > Date() }) {
        return slack.updateStatus("In a meeting",
                                  emoji: ":spiral_calendar_pad:",
                                  expiration: meeting.endDate)
    }
    else if let travel = todaysRemainingEvents.first(where: { $0.isAllDay && $0.title.hasPrefix("Travel: ") && $0.isMine }) {
        let destination = travel.title.replacingOccurrences(of: "Travel: ", with: "")
        let shortDate = DateFormatter.shortDate.string(from: travel.endDate)
        return slack.updateStatus("In \(destination) until \(shortDate)",
                                  emoji: ":airplane:",
                                  expiration: travel.endDate)
    }

    exit(0)
}
.done {
    exit(0)
}
.catch { error in
    print(String(describing: error))
    exit(1)
}

RunLoop.current.run()
