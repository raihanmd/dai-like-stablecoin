import "~/styles/globals.css";

import { type Metadata } from "next";
import { Geist } from "next/font/google";
import RootProvider from "~/provider/root-provider";
import Header from "~/_components/header";

export const metadata: Metadata = {
  title: "Decentralized Stablecoin",
  description: "A simple decentralized stablecoin.",
  icons: [{ rel: "icon", url: "/favicon.ico" }],
};

const geist = Geist({
  subsets: ["latin"],
  variable: "--font-geist-sans",
});

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" className={`${geist.variable} dark`}>
      <body>
        <RootProvider>
          <Header />
          {children}
        </RootProvider>
      </body>
    </html>
  );
}
