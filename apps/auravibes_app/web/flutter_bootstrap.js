{{flutter_js}}
{{flutter_build_config}}

const progress = document.querySelector('[data-flutter-progress]');
const progressBar = document.querySelector('[data-flutter-progress-bar]');
const setProgress = (value) => {
  progress?.setAttribute('aria-valuenow', String(value));
  if (progressBar) progressBar.style.width = `${value}%`;
};

setProgress(20);
_flutter.loader.load({
  onEntrypointLoaded: async (engineInitializer) => {
    setProgress(50);
    const appRunner = await engineInitializer.initializeEngine();
    setProgress(80);
    await appRunner.runApp();
    document.querySelector('[data-flutter-loader]')?.remove();
  },
});
