"use client";

import { type PropsWithChildren } from "react";
import { Toaster } from "react-hot-toast";

import ReactQueryProvider from "./react-query-provider";
import WagmiProvider from "./wagmi-provider";

export default function RootProvider({ children }: PropsWithChildren) {
  return (
    <ReactQueryProvider>
      <WagmiProvider>{children}</WagmiProvider>
      <Toaster />
    </ReactQueryProvider>
  );
}
