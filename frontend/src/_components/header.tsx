"use client";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { Menu, X } from "lucide-react";
import Image from "next/image";
import Link from "next/link";
import { useEffect, useState } from "react";

import { cn } from "~/lib/utils";

export default function Header() {
  const [isScrolled, setIsScrolled] = useState(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 50);
    };

    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  return (
    <header className="fixed top-0 right-0 left-0 z-50 p-4">
      <div
        className={cn(
          "mx-auto flex max-w-6xl items-center justify-between rounded-2xl transition-all duration-500 ease-in-out",
          isScrolled
            ? "bg-background/50 border-border/50 max-w-5xl rounded-3xl border px-4 py-3 shadow-lg backdrop-blur-[3px]"
            : "border-border/20 px-8 py-4",
        )}
      >
        {/* Logo */}
        <Link href="/" className="flex cursor-pointer items-center gap-2">
          <Image src="/favicon.ico" alt="Logo" width={32} height={32} />
          <span className="text-foreground hidden font-semibold sm:block">
            Decentralized Stablecoin
          </span>
        </Link>

        {/* Navigation - Desktop
        <nav className="hidden items-center gap-8 md:flex">
          <a
            href="#"
            className="text-foreground/70 hover:text-foreground text-sm transition-colors"
          >
            Home
          </a>
          <a
            href="#"
            className="text-foreground/70 hover:text-foreground text-sm transition-colors"
          >
            Features
          </a>
          <a
            href="#"
            className="text-foreground/70 hover:text-foreground text-sm transition-colors"
          >
            About
          </a>
        </nav> */}

        {/* Right Section */}
        <div className="flex items-center gap-3">
          <ConnectButton />
          {/* <RainbowKitCustomConnectButton /> */}

          {/* Mobile Menu Toggle */}
          <button
            onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
            className="hover:bg-accent/10 rounded-lg p-2 transition-colors md:hidden"
          >
            {isMobileMenuOpen ? <X size={20} /> : <Menu size={20} />}
          </button>
        </div>
      </div>

      {/* Mobile Menu */}
      {isMobileMenuOpen && (
        <div className="bg-background/90 border-border/50 animate-in fade-in slide-in-from-top-2 absolute top-full right-4 left-4 mt-2 rounded-2xl border p-4 backdrop-blur-md md:hidden">
          <nav className="flex flex-col gap-3">
            <a
              href="#"
              className="text-foreground/70 hover:text-foreground hover:bg-accent/10 rounded-lg px-4 py-2 transition-colors"
            >
              Home
            </a>
            <a
              href="#"
              className="text-foreground/70 hover:text-foreground hover:bg-accent/10 rounded-lg px-4 py-2 transition-colors"
            >
              Features
            </a>
            <a
              href="#"
              className="text-foreground/70 hover:text-foreground hover:bg-accent/10 rounded-lg px-4 py-2 transition-colors"
            >
              About
            </a>
          </nav>
        </div>
      )}
    </header>
  );
}
