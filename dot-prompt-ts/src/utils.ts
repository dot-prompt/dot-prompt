import { z } from "zod";
import { type ResponseContract } from "./models.js";
import { ValidationError } from "./errors.js";

/**
 * Validates a response object against a contract's field definitions.
 * Converts the contract's type strings to Zod schemas for runtime validation.
 *
 * @param response - The data to validate.
 * @param contract - The contract containing field definitions.
 * @returns boolean - true if valid, throws ValidationError if not.
 */
export function validateResponse(
  response: unknown,
  contract: ResponseContract
): boolean {
  if (typeof response !== "object" || response === null) {
    throw new ValidationError(422, "Response must be an object");
  }

  const schemaShape: Record<string, z.ZodTypeAny> = {};

  for (const [key, field] of Object.entries(contract.fields)) {
    schemaShape[key] = mapTypeToZod(field.type);
  }

  const schema = z.object(schemaShape);
  const result = schema.safeParse(response);

  if (!result.success) {
    throw new ValidationError(422, `Contract validation failed: ${result.error.message}`);
  }

  return true;
}

/**
 * Maps contract type strings to Zod types.
 *
 * @param type - The type string from the contract (e.g., 'string', 'number').
 * @returns z.ZodTypeAny
 */
function mapTypeToZod(type: string): z.ZodTypeAny {
  switch (type.toLowerCase()) {
    case "string":
      return z.string();
    case "number":
    case "float":
    case "integer":
      return z.number();
    case "boolean":
      return z.boolean();
    case "array":
      return z.array(z.any());
    case "object":
      return z.record(z.any());
    default:
      return z.any();
  }
}

/**
 * Sleep for a specified number of milliseconds.
 *
 * @param ms - Milliseconds to sleep.
 */
export const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));
