import { loadFixture, ethers, expect, time } from "./setup"
import type {LowkickStarter} from "../typechain-types"
import {Campaign__factory} from "../typechain-types"
describe("LowkickStarter" , () => {
    const deploy = async () => {
        const [owner, pledger] = await ethers.getSigners();

        const LowkickStarterFactory = await ethers.getContractFactory("LowkickStarter");
        const lowkick:LowkickStarter = await LowkickStarterFactory.deploy()
        await lowkick.deployed()

        return {lowkick, owner, pledger}
    }

    it('allows to pledge and claim', async () => {
        const {lowkick, owner, pledger} = await loadFixture(deploy);

        const endsAt = Math.floor(Date.now() / 1000) + 30;
        const startTx = await lowkick.start(1000, endsAt)
        await startTx.wait();

        const campaignAddr =  (await lowkick.campaigns(1)).targetContract;
        const campaignAsOwner = Campaign__factory.connect(
            campaignAddr,
            owner
        );

        expect(await campaignAsOwner.endsAt()).to.eq(endsAt);
        const campaignAsPledger = Campaign__factory.connect(
            campaignAddr,
            pledger
        );

        const pledgeTx = await campaignAsPledger.pledge({value:1500});
        await pledgeTx.wait()

        await expect(campaignAsOwner.claim()).to.be.reverted;
        expect((await lowkick.campaigns(1)).claimed).to.be.false;
        
        await time.increase(40);
        
        await expect(() => campaignAsOwner.claim()).
        to.changeEtherBalances([campaignAsOwner, owner], [-1500, 1500]);
        
        expect((await lowkick.campaigns(1)).claimed).to.be.true;
    })
})