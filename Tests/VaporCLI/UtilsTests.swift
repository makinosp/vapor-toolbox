//
//  UtilsTests.swift
//  VaporCLI
//
//  Created by Sven A. Schmidt on 24/06/2016.
//
//

import XCTest
@testable import VaporCLI

import libc
enum Status {
    case ok
    case error(Error)
}


struct TestShell {
    let onExecute: (String) -> ()
    var result: Int32 = 0
    var fileExists = false
    var failed = false
    var failureMessage: String?

    init(onExecute: (String) -> () = {_ in }) {
        self.onExecute = onExecute
    }
}

extension TestShell: PosixSubsystem {

    func system(_ command: String) -> Int32 {
        self.onExecute(command)
        return self.result
    }

    func fileExists(_ path: String) -> Bool {
        return fileExists
    }

    func fail(_ message: String, cancelled: Bool) {
    }

}


class UtilsTests: XCTestCase {

    // required by LinuxMain.swift
    static var allTests: [(String, (UtilsTests) -> () throws -> Void)] {
        return [
            ("test_getCommand", test_getCommand),
            ("test_ShellCommand_run", test_ShellCommand_run),
            ("test_ShellCommand_run_cancelled", test_ShellCommand_run_cancelled),
            ("test_ShellCommand_run_error", test_ShellCommand_run_error),
        ]
    }

    func test_ShellCommand_run() {
        var executed = [String]()
        let shell = TestShell(onExecute: { cmd in executed.append(cmd) })
        do {
            try ShellCommand("ls -l").run(in: shell)
            // don't even need to wrap the String as it's typealised to ShellCommand:
            try "ls -la".run(in: shell)
            XCTAssertEqual(executed, ["ls -l", "ls -la"])
        } catch {
            XCTFail()
        }
    }

    func test_ShellCommand_run_cancelled() {
        var shell = TestShell()
        shell.result = 2
        do {
            try "foo".run(in: shell)
            XCTFail()
        } catch Error.cancelled {
            // ok
        } catch {
            XCTFail()
        }
    }

    func test_ShellCommand_run_error() {
        var shell = TestShell()
        shell.result = 1
        do {
            try "foo".run(in: shell)
            XCTFail()
        } catch Error.system(let res) {
            XCTAssertEqual(res, 1)
        } catch {
            XCTFail()
        }
    }

    func test_getCommand() {
        let cmds: [Command.Type] = [Docker.Init.self, Docker.Build.self, Docker.Run.self]
        if let res = getCommand(id: "init", commands: cmds) {
            // XCTAssertEqual cannot compare Command.Type, need to coerce to string
            XCTAssertEqual("\(res)", "\(Docker.Init.self)")
        } else {
            XCTFail()
        }
    }

}
