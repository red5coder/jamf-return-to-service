# jamf-return-to-service
With the release of Jamf Pro 10.50, a new API endpoint was added, which introduces the new Return To Service feature for iOS 17 and iPadOS 17.

Return to Service enables a mobile device management server (MDM) such as Jamf Pro to send a wipe command (Erase All Content and Settings) that includes an enrollment profile and Wi-Fi profile.

This allows you to wipe the device and have it automatically re-enroll straight back to the home screen without user interaction.

This app is a POC to demonstrate this new feature. When launched you can ask it to fetch a list of configuration profiles that contain a wi-fi payload from Jamf Pro. Just select which one you want to use and enter the serial number of the mobile device.

### Requirements

- A Mac running macOS Ventura (13.0) or higher to run this app
- Jamf Pro 10.50 or higher
- The iOS and iPadOS devices must be running v17+
- The iOS and iPadOS must be enabled for Automated Enrollment
- A Wi-Fi configuration profile that can be used with the Return of Service. This profile must allow wi-fi access without user interaction and must not use a captive portal. Make sure this profile stays scoped to the device after enrollment.
- Jamf Pro Account or API Role / Client that has the following minimum permissions
  - Read Mobile Devices
  - Read Mobile Device Configuration Profiles
  - Send Mobile Device Remote Wipe Command
  - View MDM Command Information in Jamf Pro API

### PLEASE NOTE THIS IS CURRENTLY IN BETA

### History

- 0.9 , Initial release
- 0.9.5 , Now searches for configuration profiles in Jamf Pro that contain a wi-fi payload


<img width="612" alt="v0 9 5" src="https://github.com/red5coder/jamf-return-to-service/assets/29920386/434a28a6-5fb3-4ce8-b056-8bf8980c12b7">
