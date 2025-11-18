"use client";

import "@rainbow-me/rainbowkit/styles.css";

import { darkTheme, RainbowKitProvider } from "@rainbow-me/rainbowkit";
import { type PropsWithChildren } from "react";
import { WagmiProvider as _WagmiProvider } from "wagmi";

import { config } from "~/lib/wallet/rainbow-config";

export default function WagmiProvider({ children }: PropsWithChildren) {
  return (
    <_WagmiProvider config={config}>
      <RainbowKitProvider theme={darkTheme()}>{children}</RainbowKitProvider>
    </_WagmiProvider>
  );
}
