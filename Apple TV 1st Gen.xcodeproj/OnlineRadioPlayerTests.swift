import Testing
@testable import YourAppModuleName

@Suite("Online Radio Player basic tests")
struct OnlineRadioPlayerTests {
    @Test("Construct and play URL without crashing")
    func playURL() async throws {
        let player = OnlineRadioPlayer.shared
        player.configureAudioSessionIfNeeded()

        let station = RadioStation(name: "Test", url: URL(string: "https://kexp-mp3-128.streamguys1.com/kexp128.mp3")!)
        player.play(station: station)

        // We can't assert playback, but we can assert state flips
        #expect(player.isPlaying == true)
        #expect(player.currentStation?.name == "Test")

        player.stop()
        #expect(player.isPlaying == false)
        #expect(player.currentStation == nil)
    }
}

