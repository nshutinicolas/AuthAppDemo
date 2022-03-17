//
// SignInWithEmailValidationTest.swift
// AuthenticationAppTests
//
// Created by Musoni nshuti Nicolas on 17/03/2022
// Copyright © 2022 GHOST TECHNOLOGIES LLC. All rights reserved.
//

import XCTest
@testable import AuthenticationApp

class SignInWithEmailValidationTest: XCTestCase {
    
    var validation: ValidationService!

    override func setUp() {
        super.setUp()
        validation = ValidationService()
    }
    
    override func tearDown() {
        super.tearDown()
        validation = nil
    }
    
    func testEmailValidation() throws {
        
    }
    
    func testPasswordValidation() throws {
        
    }
    
}
