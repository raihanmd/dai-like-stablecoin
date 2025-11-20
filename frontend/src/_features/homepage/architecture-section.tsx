export default function ArchitectureSection() {
  return (
    <section className="border-border/50 relative border-t px-4 py-20 sm:px-6 lg:px-8">
      <div className="mx-auto max-w-6xl">
        <div className="mb-16 space-y-4 text-center">
          <h2 className="text-4xl font-bold tracking-tight sm:text-5xl">
            System Architecture
          </h2>
          <p className="text-muted-foreground mx-auto max-w-2xl text-lg">
            Modular design with clear separation of concerns for maximum
            security and scalability.
          </p>
        </div>

        <div className="grid grid-cols-1 gap-8 md:grid-cols-2">
          {/* Core Components */}
          <div className="space-y-6">
            <div className="border-border/50 bg-muted/30 space-y-3 rounded-xl border p-6">
              <h3 className="text-foreground text-lg font-semibold">
                DSCEngine
              </h3>
              <p className="text-muted-foreground text-sm">
                Core protocol logic managing deposits, minting, liquidations,
                and health factor calculations.
              </p>
              <ul className="text-muted-foreground space-y-2 text-sm">
                <li>• Deposit & Withdraw Collateral</li>
                <li>• Mint & Burn DSC</li>
                <li>• Liquidation System</li>
                <li>• Health Factor Monitoring</li>
              </ul>
            </div>

            <div className="border-border/50 bg-muted/30 space-y-3 rounded-xl border p-6">
              <h3 className="text-foreground text-lg font-semibold">
                Pyth Oracle
              </h3>
              <p className="text-muted-foreground text-sm">
                Real-time price feeds with sub-second latency for accurate
                collateral valuations.
              </p>
              <ul className="text-muted-foreground space-y-2 text-sm">
                <li>• Push Model Updates</li>
                <li>• WETH/USD Price</li>
                <li>• WBTC/USD Price</li>
              </ul>
            </div>
          </div>

          {/* Tokens & Security */}
          <div className="space-y-6">
            <div className="border-border/50 bg-muted/30 space-y-3 rounded-xl border p-6">
              <h3 className="text-foreground text-lg font-semibold">
                DecentralizedStableCoin
              </h3>
              <p className="text-muted-foreground text-sm">
                ERC20 stablecoin token with burn capability and restricted
                minting by DSCEngine.
              </p>
              <ul className="text-muted-foreground space-y-2 text-sm">
                <li>• ERC20 Standard</li>
                <li>• Burn Capability</li>
                <li>• Owner-Restricted Minting</li>
              </ul>
            </div>

            <div className="border-border/50 bg-muted/30 space-y-3 rounded-xl border p-6">
              <h3 className="text-foreground text-lg font-semibold">
                Security
              </h3>
              <p className="text-muted-foreground text-sm">
                Multi-layer protection against reentrancy and protocol
                exploitation.
              </p>
              <ul className="text-muted-foreground space-y-2 text-sm">
                <li>• ReentrancyGuard Protection</li>
                <li>• Health Factor Validation</li>
                <li>• Input Validation</li>
              </ul>
            </div>
          </div>
        </div>

        {/* Collateral Info */}
        <div className="border-border/50 bg-muted/30 mt-12 rounded-xl border p-8">
          <h3 className="text-foreground mb-6 text-lg font-semibold">
            Supported Collateral
          </h3>
          <div className="grid grid-cols-1 gap-8 md:grid-cols-2">
            <div className="space-y-2">
              <h4 className="text-foreground font-medium">
                WETH (Wrapped Ether)
              </h4>
              <p className="text-muted-foreground text-sm">
                Ethereum's native asset wrapped as ERC20. Primary collateral
                with high liquidity.
              </p>
            </div>
            <div className="space-y-2">
              <h4 className="text-foreground font-medium">
                WBTC (Wrapped Bitcoin)
              </h4>
              <p className="text-muted-foreground text-sm">
                Bitcoin wrapped on Ethereum. Provides additional collateral
                diversification.
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
