import { z } from "zod";

/**
 * Zod schema for parameter specification.
 */
export const ParamSpec = z.object({
  type: z.string(),
  lifecycle: z.string().optional(),
  doc: z.string().optional(),
  default: z.any().optional(),
  values: z.array(z.any()).optional(),
  range: z.tuple([z.any(), z.any()]).optional(),
});
export type ParamSpec = z.infer<typeof ParamSpec>;

/**
 * Zod schema for fragment specification.
 */
export const FragmentSpec = z.object({
  type: z.string(),
  doc: z.string().optional(),
  from_path: z.string().optional(),
});
export type FragmentSpec = z.infer<typeof FragmentSpec>;

/**
 * Zod schema for a single field in a response contract.
 */
export const ContractField = z.object({
  type: z.string(),
  doc: z.string().optional(),
});
export type ContractField = z.infer<typeof ContractField>;

/**
 * Zod schema for a response contract.
 */
export const ResponseContract = z.object({
  fields: z.record(ContractField),
  compatible: z.boolean(),
});
export type ResponseContract = z.infer<typeof ResponseContract>;

/**
 * Zod schema for a prompt schema.
 */
export const PromptSchema = z.object({
  name: z.string(),
  version: z.number(),
  description: z.string().optional(),
  mode: z.string().optional(),
  docs: z.string().optional(),
  params: z.record(ParamSpec),
  fragments: z.record(FragmentSpec),
  contract: ResponseContract.optional(),
});
export type PromptSchema = z.infer<typeof PromptSchema>;

/**
 * Zod schema for compilation result.
 */
export const CompileResult = z.object({
  template: z.string(),
  cache_hit: z.boolean(),
  compiled_tokens: z.number(),
  vary_selections: z.record(z.any()).optional(),
  response_contract: z.record(z.any()).optional(),
  version: z.number(),
  warnings: z.array(z.string()).default([]),
});
export type CompileResult = z.infer<typeof CompileResult>;

/**
 * Zod schema for rendering result.
 */
export const RenderResult = z.object({
  prompt: z.string(),
  response_contract: z.record(z.any()).optional(),
  cache_hit: z.boolean(),
  compiled_tokens: z.number(),
  injected_tokens: z.number(),
  vary_selections: z.record(z.any()).optional(),
});
export type RenderResult = z.infer<typeof RenderResult>;

/**
 * Zod schema for injection result.
 */
export const InjectResult = z.object({
  prompt: z.string(),
  injected_tokens: z.number(),
});
export type InjectResult = z.infer<typeof InjectResult>;

/**
 * Event types for SSE stream.
 */
export const DotPromptEvent = z.discriminatedUnion("type", [
  z.object({ type: z.literal("breaking_change"), timestamp: z.number(), payload: z.any() }),
  z.object({ type: z.literal("versioned"), timestamp: z.number(), payload: z.any() }),
  z.object({ type: z.literal("committed"), timestamp: z.number(), payload: z.any() }),
]);
export type DotPromptEvent = z.infer<typeof DotPromptEvent>;
