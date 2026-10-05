import SwiftUI

struct PrivacyView: View {
    var body: some View {
        Screen {
            SectionTitle(title: "Your bar stays yours.", caption: "Privacy policy · Updated October 5, 2026")
            policySection("Your information stays on your iPhone", "Pour stores your selected ingredients, favorite recipes, and measurement preference on your device. It uses this information to suggest drinks and ingredients to buy. Pour does not require an account or send this information to us.")
            policySection("No analytics or tracking", "The app contains no advertising, analytics, or tracking SDKs. It does not collect location, contacts, advertising identifiers, or usage data. Recipes and illustrations are included in the app, so browsing and recommendations work offline.")
            policySection("Your choices and backups", "You can change or clear your shelf in My bar and remove favorites from Recipes or a recipe detail. Deleting the app removes its local data. Your device backup may include this data, depending on your Apple settings, and restoring a backup may restore it. Pour does not run its own cloud backup or sync service.")
            policySection("Keyboard dictation", "If you use the microphone on the iPhone keyboard to enter ingredients, dictation is handled by Apple or your chosen keyboard provider under its own privacy settings. Pour receives the text you enter, not an audio recording.")
            policySection("Website and support", "The Pour website has no analytics, advertising, or tracking cookies. Its hosting provider may process standard request information, such as your IP address, to serve the pages. If you follow a support link, the service you open has its own privacy policy. Information you choose to include in a support request is used to respond and investigate the issue. GitHub issues are public, so do not include personal or sensitive information.")
            policySection("Changes to this policy", "If Pour changes how it handles information, this policy will be updated in the app and on the website. The date above identifies this version.")
            VStack(alignment: .leading, spacing: 10) {
                Text("Questions about privacy?")
                    .font(.headline)
                Link("Contact Pour on GitHub", destination: URL(string: "https://github.com/andreasmcdermott/drink-app/issues")!)
                    .underline()
                Text("Opens the public issue tracker in your browser. Avoid sharing personal information.")
                    .font(.footnote).foregroundStyle(Palette.secondary)
            }
        }
        .navigationTitle("Privacy policy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func policySection(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline).accessibilityAddTraits(.isHeader)
            Text(body).font(.body)
        }
    }
}
