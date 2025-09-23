import { Strategy, AbstractStrategy } from "./strategy";
import { MultiSamlStrategy } from "./multiSamlStrategy";

import type {
  VerifiedCallback,
  VerifyWithRequest,
  VerifyWithoutRequest,
  MultiStrategyConfig,
  PassportSamlConfig,
} from "./types";

export * from "@foxden/node-saml";

export {
  AbstractStrategy,
  Strategy,
  MultiSamlStrategy,
  VerifiedCallback,
  VerifyWithRequest,
  VerifyWithoutRequest,
  MultiStrategyConfig,
  PassportSamlConfig,
};
