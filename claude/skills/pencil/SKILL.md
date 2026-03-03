---
name: pencil
description: Best practices for working with Pencil MCP tools on .pen design files. Use whenever creating, editing, or reviewing designs in Pencil — even for small updates like changing a color or moving a node. This skill ensures correct tool usage and prevents common pitfalls that waste time.
user-invokable: false
---

# Pencil MCP Best Practices

Pencil MCP tools have subtle behaviors — silent failures, property name mismatches, invisible text — that cause wasted effort if you don't anticipate them. This skill captures those patterns so you can avoid redoing work.

## Workflow

Follow this order when starting design work. Each step builds context for the next, and skipping ahead (e.g., creating nodes before checking variables) leads to inconsistencies that are tedious to fix later.

1. `get_editor_state` — understand current file and selection
2. `get_variables` — load existing design tokens
3. `batch_get` — inspect existing structure, look for reusable components
4. `batch_design` — create/update nodes
5. `get_screenshot` — visually verify changes

Before creating anything new, search for existing components, logos, and assets you can copy. Pencil files accumulate reusable elements over time, and copying them ensures consistency. When redesigning an existing screen, `batch_get` the current structure first so you can preserve what works.

## Design vs Implementation

Design and implementation are separate phases. Changing code before the design is confirmed creates rework when the design changes — and it almost always does.

- Read the implementation code first to understand actual behavior before designing
- Do not modify code until the design is confirmed by the user
- For LP or UI screen design, confirm the direction and references with the user before starting

## Design Tokens

Colors and shared values should come from variables, not hardcoded values. Hardcoded colors drift across screens and make theming impossible.

- Run `get_variables` at the start to see what tokens exist
- Reference tokens with `$variable-name` syntax in node properties (e.g., `fill: "$foreground"`)
- Define new tokens with `set_variables` BEFORE creating nodes that use them — nodes created with hardcoded values won't retroactively pick up variables
- `replace_all_matching_properties` escapes `$` to `\$`, which breaks variable references. Use `batch_design` `U()` to set variable references instead
- `$varName` syntax only works for color properties. `fontSize` does not support variable references — use literal values there

## Frames

Frames are the top-level containers on the canvas. They anchor the design's structure.

- Do not delete existing frames — other frames or exports may reference them, and deletion can silently break those links
- Do not overlap frames — overlapping causes confusing behavior in screenshots and layout calculations. Use `find_empty_space_on_canvas` (requires `filePath` parameter) to find clear canvas area
- Respect the size conventions already established in the file
- For design iterations, create a new frame beside the existing one rather than modifying in place. This preserves the before/after for comparison
- Set `placeholder: true` when starting work on a frame, and `placeholder: false` when done

## batch_design

The primary tool for creating and modifying nodes. Its operation model has some constraints worth understanding upfront:

- Maximum 25 operations per call. This is an API limit — split larger changes across multiple calls
- Every `I()`, `C()`, `R()` must have a binding name (e.g., `foo=I(...)`) so you can reference the created node
- Bindings are only valid within the same call — they don't carry over
- `I()` does not support index positioning. To control ordering, insert first, then call `M()` in a separate `batch_design` call
- `M(nodeId, parent, index)` requires a literal node ID. Binding variables don't work here because Move resolves IDs differently from other operations

### Copy Behavior

When you `C()` a node, Pencil generates new IDs for all descendants. The IDs you saw in `batch_get` before the copy are no longer valid for the copied subtree. If you need to update children of a copied node, run `batch_get` on the copy first to discover the new IDs, then update in a subsequent `batch_design` call.

## Text Nodes

Text rendering has several non-obvious defaults that cause invisible or broken output:

- Text has no fill by default (transparent). Set `fill` explicitly (e.g., `fill: "$text-primary"`) or the text will be invisible on the canvas
- Use `content` for text value, not `text` — `text` is silently ignored
- `fontFamily` must be a concrete font name like `Inter`, `Roboto Mono`, or `JetBrains Mono`. Generic families (`system-ui`, `sans-serif`, `monospace`) are invalid and cause fallback rendering
- Set `textGrowth` before setting `width`/`height` — without textGrowth, dimension properties may not take effect on text nodes
- `underline` may not render in Pencil screenshots even when set correctly. Note this for CSS implementation later

## Property Names

Pencil uses its own property names that differ from CSS and Figma. Using the wrong name silently fails — the property is just ignored.

| Use this | Not this | Notes |
|----------|----------|-------|
| `fill` | `fills` | Single value, supports `$var` refs |
| `layout` | `layoutMode` | Values: `vertical`, `horizontal` |
| `gap` | `itemSpacing` | Spacing between layout children |
| `content` | `text` | Text node content |
| `justifyContent` / `alignItems` | `mainAxisAlignment` / `crossAxisAlignment` | Center alignment |

When unsure about a property name, `batch_get` an existing node that has the property you want and copy its naming. This is the most reliable way to discover correct names.

## Layout

- Prefer `fill_container` over hardcoded widths for children — this makes layouts responsive to parent changes
- Use `fit_content` for container height unless a fixed viewport size is needed
- Use `snapshot_layout` to inspect computed layout rectangles when debugging spacing issues

## Image Generation

- `G()` saves generated files to `images/` directory. If you delete the node later, clean up the image file manually — Pencil doesn't auto-delete it
- AI-generated images work well for placeholders and illustrations, but may not match specific pixel art or logos. Copy user-provided images with `C()` instead

## Bulk Updates

When updating text or properties across many nodes, use `batch_get` with `patterns` + `searchDepth` to search the full document first, then apply changes in bulk. This approach is faster and less error-prone than hunting for nodes one by one.

## Design Exploration

When exploring multiple options, create variants as separate frames side by side and screenshot all of them for comparison. Delete rejected variants afterward to keep the canvas navigable.

## Verification

Run `get_screenshot` after every set of changes. Many issues — invisible text, wrong colors, misalignment — are only catchable visually. Use `batch_get` with `resolveVariables: true` to verify that computed values match your expectations.

## Project-Specific Configuration

This skill covers universal Pencil best practices. Project-specific values belong in each repository's CLAUDE.md:

- Font family (e.g., JetBrains Mono, Inter)
- Style guide name (e.g., base-lyra)
- Typography scale
- Design file path (e.g., `design.pen`, `project.pen`)
- Design principles (e.g., OOUI, modeless)
- Icon library
- Design value constraints (e.g., Tailwind standard scale)
