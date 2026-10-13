import { SearchModeSwitcher } from "chrome://browser/content/urlbar/SearchModeSwitcher.mjs";

console.warn("[userchrome.js] booting!");

const startup = new Promise(resolve => {
    Services.obs.addObserver(() => {
        resolve()
    }, "sessionstore-windows-restored");
});

console.warn("[userchrome.js]  what is my globalThis !!!! ", globalThis);

startup.then(async () => {
    console.warn("[userchrome.js] startup finished!");

    console.warn("[userchrome.js] disabling it once...");

    ChromeUtils.userChromeGlobalThis = globalThis;
    SearchModeSwitcher.userChromeGlobalThis = globalThis;

    // stop these binds. i want to use them for tab navigation
    // https://github.com/mozilla-firefox/firefox/blob/64cfaf34e56f4c82eea77d032ec592c083b5b161/browser/components/urlbar/content/SearchModeSwitcher.mjs#L456-L461
    SearchModeSwitcher.prototype.handleKeyDown = () => { }

    console.warn("[userchrome.js] disabled it once.");

    await new Promise(resolve => setTimeout(resolve, 15000));

    console.warn("[userchrome.js] disabling it twice...");

    SearchModeSwitcher.prototype.handleKeyDown = () => { }

    console.warn("[userchrome.js] disabled it twice.");
});