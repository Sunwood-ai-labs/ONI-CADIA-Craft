import { defineConfig } from "vitepress";

const repo = "https://github.com/Sunwood-ai-labs/ONI-CADIA";
const base = "/ONI-CADIA/";

export default defineConfig({
  title: "ONI-CADIA",
  description:
    "AGI-country simulator where OpenClaw citizens live inside ONI-CADIA, with Podman-isolated runtimes, civic persona scaffolds, and a local Mattermost public square.",
  lang: "en-US",
  base,
  cleanUrls: true,
  lastUpdated: true,
  head: [
    ["link", { rel: "icon", type: "image/svg+xml", href: `${base}favicon.svg` }],
    ["meta", { name: "theme-color", content: "#1a0505" }],
  ],
  themeConfig: {
    siteTitle: "ONI-CADIA",
    logo: "/favicon.svg",
    socialLinks: [{ icon: "github", link: repo }],
    footer: {
      message: "Released under the MIT License.",
      copyright: "Copyright (c) 2026 Sunwood-ai-labs",
    },
  },
  locales: {
    root: {
      label: "English",
      lang: "en-US",
      themeConfig: {
        nav: [
          { text: "Guide", link: "/guide/quickstart" },
          { text: "Country Simulation Guide", link: "/guide/agent-teams" },
          { text: "Configuration", link: "/guide/configuration" },
          { text: "Validation", link: "/guide/validation" },
          { text: "Releases", link: "/guide/releases" },
          { text: "Articles", link: "/guide/articles" },
          { text: "GitHub", link: repo },
        ],
        sidebar: [
          {
            text: "Guide",
            items: [
              { text: "Quick Start", link: "/guide/quickstart" },
              { text: "Country Simulation Guide", link: "/guide/agent-teams" },
              { text: "Configuration", link: "/guide/configuration" },
              { text: "Validation", link: "/guide/validation" },
            ],
          },
          {
            text: "Release Collateral",
            items: [
              { text: "Release Notes Index", link: "/guide/releases" },
              { text: "v0.1.0 Release Notes", link: "/guide/releases/v0.1.0" },
              { text: "Articles Index", link: "/guide/articles" },
              { text: "Launching v0.1.0", link: "/guide/articles/v0.1.0-launch" },
            ],
          },
        ],
      },
    },
    ja: {
      label: "Japanese",
      lang: "ja-JP",
      themeConfig: {
        nav: [
          { text: "ガイド", link: "/ja/guide/quickstart" },
          { text: "国家シミュレーション", link: "/ja/guide/agent-teams" },
          { text: "設定", link: "/ja/guide/configuration" },
          { text: "検証", link: "/ja/guide/validation" },
          { text: "リリース", link: "/ja/guide/releases" },
          { text: "記事", link: "/ja/guide/articles" },
          { text: "GitHub", link: repo },
        ],
        sidebar: [
          {
            text: "ガイド",
            items: [
              { text: "クイックスタート", link: "/ja/guide/quickstart" },
              { text: "国家シミュレーションガイド", link: "/ja/guide/agent-teams" },
              { text: "設定", link: "/ja/guide/configuration" },
              { text: "検証", link: "/ja/guide/validation" },
            ],
          },
          {
            text: "リリース資料",
            items: [
              { text: "リリースノート一覧", link: "/ja/guide/releases" },
              { text: "v0.1.0 リリースノート", link: "/ja/guide/releases/v0.1.0" },
              { text: "記事一覧", link: "/ja/guide/articles" },
              { text: "v0.1.0 を公開", link: "/ja/guide/articles/v0.1.0-launch" },
            ],
          },
        ],
      },
    },
  },
});
