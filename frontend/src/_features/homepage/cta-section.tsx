export default function CTASection() {
  return (
    <section className="relative px-4 py-20 sm:px-6 lg:px-8">
      <div className="mx-auto max-w-4xl">
        <div className="border-border/50 bg-muted/30 space-y-6 rounded-2xl border p-12 text-center">
          <h2 className="text-4xl font-bold tracking-tight sm:text-5xl">
            Ready to Get Started?
          </h2>
          <p className="text-muted-foreground mx-auto max-w-2xl text-lg">
            Join our decentralized finance protocol and start earning with your
            collateral today.
          </p>

          <div className="flex flex-col justify-center gap-4 pt-4 sm:flex-row">
            <a
              href="#"
              className="bg-foreground text-background inline-flex items-center justify-center rounded-lg px-8 py-3 font-medium transition-opacity hover:opacity-90"
            >
              Launch App
            </a>
            <a
              href="#"
              className="border-border/50 text-foreground hover:bg-muted/50 inline-flex items-center justify-center rounded-lg border px-8 py-3 font-medium transition-colors"
            >
              View on GitHub
            </a>
          </div>
        </div>

        {/* Info Box */}
        <div className="border-border/50 bg-muted/20 mt-12 rounded-xl border p-6">
          <p className="text-muted-foreground text-center text-sm">
            ⚠️ This project is for educational purposes. Always conduct thorough
            security audits before using in production.
          </p>
        </div>
      </div>
    </section>
  );
}
