//
//  DailyProgrammerMarkdown.swift
//  
//
//  Created by Craig Siemens on 2016-01-17.
//
//

import Foundation



enum Category {
    case Easy
    case Intermediate
    case Hard
    case Other
}

struct Thread {
    let id: String
    let date: NSDate
    let title: String
    let link: String
    
    init?(data: [String: AnyObject]) {
        guard let id = data["id"] as? String,
            let timeStamp = data["created_utc"] as? NSTimeInterval,
            var title = data["title"] as? String,
            let link = data["permalink"] as? String else {
                return nil
        }
        
        title = title.stringByReplacingOccurrencesOfString("\n", withString: "")
        if title.containsString("]") && !title.hasPrefix("[") {
            title = "[" + title
        }
        
        self.id = id
        self.date = NSDate(timeIntervalSince1970: timeStamp)
        self.title = title
        self.link = link
    }
    
    var category: Category {
        let mapping: [String: Category] = [
            "easy": .Easy, "intermediate": .Intermediate, "medium": .Intermediate, "hard": .Hard, "difficult": .Hard
        ]
        
        for (subString, category) in mapping {
            if title.lowercaseString.containsString(subString) {
                return category
            }
        }
        
        return .Other
    }
    
    var number: Int {
        let components = NSCalendar.currentCalendar().components([.YearForWeekOfYear, .WeekOfYear], fromDate: date)
        return components.yearForWeekOfYear * 100 + components.weekOfYear
    }
    
    var markdown: String {
        return "[\(title)](\(link))"
    }
}

class Week {
    let number: Int
    var easy = [Thread]()
    var intermediate = [Thread]()
    var hard = [Thread]()
    var other = [Thread]()
    
    init(number: Int) {
        self.number = number
    }
    
    func addThread(thread: Thread) {
        switch thread.category {
        case .Easy:
            easy.append(thread)
        case .Intermediate:
            intermediate.append(thread)
        case .Hard:
            hard.append(thread)
        case .Other:
            other.append(thread)
        }
    }
    
    var markdown: String {
        let easyMarkdown = easy.map({ $0.markdown }).joinWithSeparator("<br><br>")
        let intermediateMarkdown = intermediate.map({ $0.markdown }).joinWithSeparator("<br><br>")
        let hardMarkdown = hard.map({ $0.markdown }).joinWithSeparator("<br><br>")
        let otherMarkdown = other.map({ $0.markdown }).joinWithSeparator("<br><br>")
        return "| \(easyMarkdown) | \(intermediateMarkdown) | \(hardMarkdown) | \(otherMarkdown) |"
    }
}

var weeksByNumber = [Int: Week]()
func weekForNumber(number: Int) -> Week {
    if let week = weeksByNumber[number] {
        return week
    }
    
    let week = Week(number: number)
    weeksByNumber[number] = week
    return week
}

func loadThreads(after: Thread?) -> Thread? {
    var urlString = "https://api.reddit.com/r/dailyprogrammer.json"
    
    if let after = after {
        urlString += "?count=25&after=t3_\(after.id)"
    }
    
    guard let url = NSURL(string: urlString),
        let data = NSData(contentsOfURL: url),
        let json = try? NSJSONSerialization.JSONObjectWithData(data, options: []),
        let childData = json.valueForKeyPath("data.children.@unionOfObjects.data") as? [[String: AnyObject]] else {
            return nil
    }
    
    let threads = childData.flatMap(Thread.init)
    for thread in threads {
        weekForNumber(thread.number).addThread(thread)
    }
    
    return threads.last
}

var lastThread: Thread?
repeat {
    lastThread = loadThreads(lastThread)
} while lastThread != nil

print("Easy | Intermediate | Hard | Other")
print("---|---|---|---")

let weeks = weeksByNumber.values.sort { $0.number > $1.number }
for week in weeks {
    print(week.markdown)
}
