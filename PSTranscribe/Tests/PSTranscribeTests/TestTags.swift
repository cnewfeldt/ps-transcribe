import Testing

extension Tag {
    /// Marks a test that requires real FluidAudio model files on disk and performs actual model
    /// loading. These tests are excluded from the default `swift test` run and must be invoked
    /// with `--filter TranscriptionEngineReloadModelsTests` or equivalent tag inclusion.
    @Tag static var integration: Self
}
