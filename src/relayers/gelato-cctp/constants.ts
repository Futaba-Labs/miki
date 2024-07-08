export const TWO_HOURS = 2 * 60 * 60 * 1000;

interface INetwork {
  domain: number;
  mikiCCTPAdapter: string;
  mikiCCTPReceiver: string;
  circleTokenMessenger: string;
  circleMessageTransmitter: string;
  usdc: string;
}

export enum ChainId {
  Arbitrum = 421614, // Arbitrum Sepolia
  Base = 84532, // Base Sepolia
}

export const NETWORKS: { [id in ChainId]: INetwork } = {
  [ChainId.Arbitrum]: {
    domain: 3,
    mikiCCTPAdapter: "0x330F25c20621dE38132516dcC9C7C49982B37A23",
    mikiCCTPReceiver: "",
    circleTokenMessenger: "0x9f3B8679c73C2Fef8b59B4f3444d4e156fb70AA5",
    circleMessageTransmitter: "0xaCF1ceeF35caAc005e15888dDb8A3515C41B4872",
    usdc: "0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d",
  },
  [ChainId.Base]: {
    domain: 6,
    mikiCCTPAdapter: "",
    mikiCCTPReceiver: "0x1d3E172C336D782B7d3869A9541b039DA376AA5C",
    circleTokenMessenger: "0x9f3B8679c73C2Fef8b59B4f3444d4e156fb70AA5",
    circleMessageTransmitter: "0x7865fAfC2db2093669d92c0F33AeEF291086BEFD",
    usdc: "0x036CbD53842c5426634e7929541eC2318f3dCF7e",
  },
};

export const GELATO_API = "https://api.gelato.digital";
export const CIRCLE_API = "https://iris-api-sandbox.circle.com";
