import Link from "next/link";

export default function HeroSection() {
  return (
    <section className="relative flex min-h-screen items-center justify-center px-4 pt-20 sm:px-6 lg:px-8">
      <div className="mx-auto max-w-4xl space-y-8 text-center">
        {/* Heading */}
        <div className="space-y-4">
          <h1 className="text-5xl font-bold tracking-tight text-balance sm:text-6xl">
            Decentralized{" "}
            <span className="text-muted-foreground">Stablecoin</span>
          </h1>
          <p className="text-muted-foreground mx-auto max-w-2xl text-xl text-balance">
            An algorithmic, over-collateralized stablecoin pegged to USD. Backed
            by WETH and WBTC with real-time price feeds.
          </p>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-3 gap-4 py-8 sm:gap-8">
          <div className="space-y-2">
            <p className="text-muted-foreground text-sm">Collateralization</p>
            <p className="text-2xl font-bold">200%</p>
          </div>
          <div className="space-y-2">
            <p className="text-muted-foreground text-sm">Supported Assets</p>
            <p className="text-2xl font-bold">2</p>
          </div>
          <div className="space-y-2">
            <p className="text-muted-foreground text-sm">Liquidation Bonus</p>
            <p className="text-2xl font-bold">10%</p>
          </div>
        </div>

        {/* CTA Buttons */}
        <div className="flex flex-col justify-center gap-4 pt-4 sm:flex-row">
          <Link
            href="/app"
            className="bg-foreground text-background inline-flex items-center justify-center rounded-lg px-6 py-3 font-medium transition-opacity hover:opacity-90"
          >
            Launch App
          </Link>
        </div>
      </div>
    </section>
  );
}
