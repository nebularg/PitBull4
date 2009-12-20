-- Notify modules that all embedded modules have been loaded since there are no
-- built in events for those modules loaded because WoW doesn't see them as addons
-- in their own right.
PitBull4:CallMethodOnModules("OnEmbeddedModulesLoaded")
