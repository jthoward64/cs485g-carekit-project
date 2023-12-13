//
//  Consent.swift
//  OCKSample
//
//  Created by Joshua Howard on 12/12/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

// swiftlint:disable line_length

let informedConsentHTML = """
<!DOCTYPE html>
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=400, user-scalable=no">
    <meta charset="utf-8" />
    <style type="text/css">
        ul, p, h1, h3 {
            text-align: left;
        }
    </style>
</head>
<body>
    <h1>Informed Consent</h1>
    <h3>Study Expectations</h3>
    <ul>
        <li>You will be asked to complete various tasks such as surveys and health-supporting activities.</li>
        <li>The app will autonomously access your sleep data to provide better support and feedback</li>
        <li>The app may send you notifications to remind you to complete these tasks.</li>
        <li>You will be asked to share various health data types to support your personal goals.</li>
        <li>Your information will be kept private and secure.</li>
        <li>You can delete your account at any time.</li>
    </ul>
    <h3>Eligibility Requirements</h3>
    <ul>
        <li>Must be 18 years or older.</li>
        <li>Must be the only user of the device on which you are participating in the study.</li>
        <li>Must be able to sign your own consent form.</li>
    </ul>
    <p>By signing below, I acknowledge that I have read this consent carefully, that I understand all of its terms, and that I enter into this study voluntarily. I understand that my information will only be used and disclosed for the purposes described in the consent and I can withdraw from the study at any time.</p>
    <p>Please sign using your finger below.</p>
    <br>
</body>
</html>
"""
