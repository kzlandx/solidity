## Rebase Token

What are we building?
1. A DeFi protocol that allows users to deposit into a vault and in return, receive rebase tokens that represent their underlying balance.
2. A rebase token -> `balanceOf` function is dynamic to show the changing balance with time.
    - Balance increases linearly with time
    - Mint tokens to users every time they perform an action (minting, burning, transferring, or ... bridging)
3. Interest rate
    - Individually set an interest rate for each user based on some global interest rate of the protocol at the time the user deposits into the vault.
    - This global interest rate can only decrease to incentivize/reward early adopters.
    - Increase token adoption!

Known issues:
1. In `transfer` function of `RebaseToken` contract, there is an issue. A user could deposit a small amount into the vault at first with one wallet account. This gives them, say, 0.005% interest rate. Then they deposited a larger amount into the vault with another wallet account, which gives the 2nd account, say, 0.002% interest rate. They can then transfer all their funds from the 2nd account to the 1st which has got a higher interest rate and keep the higher interest rate on all their funds from the 2nd account as well as the 1st account.