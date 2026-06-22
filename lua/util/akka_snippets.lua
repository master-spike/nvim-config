-- Custom blink.cmp source providing Akka Java SDK snippets for the avalanche
-- backend. Unlike the static JSON snippets source, this one deduces the Java
-- package from the buffer's path at completion time (mirroring how jdtls fills
-- in `package ...;` for a new file). The class name is provided via the
-- `$TM_FILENAME_BASE` snippet variable, which the snippet engine resolves to the
-- file name without its extension.

local M = {}

local types = require("blink.cmp.types")

-- Returns the byte offset of the last plain (non-pattern) occurrence of
-- `needle` in `haystack`, or nil when it is not present.
local function find_last(haystack, needle)
  local last, from = nil, 1
  while true do
    local s, e = haystack:find(needle, from, true)
    if not s then
      break
    end
    last, from = e, e + 1
  end
  return last
end

-- Deduces the Java package for the current buffer from its directory, by
-- stripping everything up to and including the source root (`src/main/java`,
-- `src/test/java`, or a bare `java`) and converting the remaining path segments
-- into a dotted package. Returns nil when no source root is found (e.g. an
-- unsaved buffer), so callers can fall back to a tabstop.
local function package_for_buffer()
  local dir = vim.fn.expand("%:p:h"):gsub("\\", "/")
  if dir == "" then
    return nil
  end

  for _, root in ipairs({ "/src/main/java/", "/src/test/java/", "/java/" }) do
    local stop = find_last(dir, root)
    if stop then
      local pkg = dir:sub(stop + 1):gsub("/", ".")
      if pkg ~= "" then
        return pkg
      end
    end
  end
  return nil
end

-- Converts a CamelCase class name into a kebab-case component id, e.g.
-- `OrderFulfilmentEventConsumer` -> `order-fulfilment-event-consumer`. Acronyms
-- are split on the boundary with the following word (`HTTPConsumer` ->
-- `http-consumer`).
local function kebab(name)
  local s = name:gsub("(%l)(%u)", "%1-%2"):gsub("(%u+)(%u%l)", "%1-%2")
  return s:lower()
end

-- A tabstop/placeholder builder shared by every snippet body. `ctx` carries the
-- values deduced from the buffer; `package` and `component_id` only consume a
-- tabstop when they could not be deduced. The class name itself is always the
-- `$TM_FILENAME_BASE` snippet variable, resolved by the snippet engine.
local function new_builder(ctx)
  local n = 0
  local b = {}
  function b.ts(default)
    n = n + 1
    return "${" .. n .. ":" .. default .. "}"
  end
  function b.package()
    return ctx.package or b.ts("com.example")
  end
  function b.component_id()
    if ctx.class_file then
      return kebab(ctx.class_file)
    end
    return b.ts("component-id")
  end
  return b
end

-- Builds the snippet body for an Akka HTTP endpoint. Tabstops are allocated
-- lazily so that the package only consumes a tabstop when it could not be
-- deduced.
local function endpoint_body(ctx)
  local b = new_builder(ctx)
  local package = b.package()
  local function ts(default)
    return b.ts(default)
  end
  local path = ts("path")
  local route = ts("/")
  local method = ts("get")

  return table.concat({
    "package " .. package .. ";",
    "",
    "import akka.http.javadsl.model.HttpResponse;",
    "import akka.javasdk.annotations.Acl;",
    "import akka.javasdk.annotations.http.Get;",
    "import akka.javasdk.annotations.http.HttpEndpoint;",
    "import akka.javasdk.client.ComponentClient;",
    "import akka.javasdk.http.AbstractHttpEndpoint;",
    "import akka.javasdk.http.HttpResponses;",
    "import org.slf4j.Logger;",
    "import org.slf4j.LoggerFactory;",
    "",
    "@Acl(allow = @Acl.Matcher(principal = Acl.Principal.INTERNET))",
    '@HttpEndpoint("/' .. path .. '")',
    "public class $TM_FILENAME_BASE extends AbstractHttpEndpoint {",
    "",
    "  private static final Logger logger = LoggerFactory.getLogger($TM_FILENAME_BASE.class);",
    "",
    "  private final ComponentClient componentClient;",
    "",
    "  public $TM_FILENAME_BASE(ComponentClient componentClient) {",
    "    this.componentClient = componentClient;",
    "  }",
    "",
    '  @Get("' .. route .. '")',
    "  public HttpResponse " .. method .. "() {",
    "    ${0:return HttpResponses.ok();}",
    "  }",
    "}",
  }, "\n")
end

-- Builds an Akka Consumer body. `annotation` is a function returning the
-- `@Consume.From...` line (allocating its own tabstops via the builder), and
-- `handler` returns the handler method's `{ name, type, param, log }`. The
-- component id is the class name in kebab case.
local function consumer_body(annotation, handler)
  return function(ctx)
    local b = new_builder(ctx)
    local package = b.package()
    local component_id = b.component_id()
    local consume = annotation(b)
    local m = handler(b)

    return table.concat({
      "package " .. package .. ";",
      "",
      "import akka.javasdk.annotations.Component;",
      "import akka.javasdk.annotations.Consume;",
      "import akka.javasdk.consumer.Consumer;",
      "import org.slf4j.Logger;",
      "import org.slf4j.LoggerFactory;",
      "",
      '@Component(id = "' .. component_id .. '")',
      consume,
      "public class $TM_FILENAME_BASE extends Consumer {",
      "",
      "  private final Logger logger = LoggerFactory.getLogger(getClass());",
      "",
      "  public Effect " .. m.name .. "(" .. m.type .. " " .. m.param .. ") {",
      '    logger.info("' .. m.log .. ': {}", ' .. m.param .. ");",
      "    ${0:return effects().done();}",
      "  }",
      "}",
    }, "\n")
  end
end

-- Each spec builds its body from the buffer context. New component snippets are
-- added here.
local specs = {
  {
    trigger = "akka-endpoint",
    description = "Akka HTTP endpoint with ComponentClient and an SLF4J logger",
    body = endpoint_body,
  },
  {
    trigger = "akka-consumer-event-sourced-entity",
    description = "Akka Consumer of an Event Sourced Entity's events",
    body = consumer_body(
      function(b)
        return "@Consume.FromEventSourcedEntity(value = " .. b.ts("SomeEntity") .. ".class)"
      end,
      function(b)
        return { name = "onEvent", type = b.ts("SomeEvent"), param = "event", log = "Received event" }
      end
    ),
  },
  {
    trigger = "akka-consumer-key-value-entity",
    description = "Akka Consumer of a Key Value Entity's state updates",
    body = consumer_body(
      function(b)
        return "@Consume.FromKeyValueEntity(value = " .. b.ts("SomeEntity") .. ".class)"
      end,
      function(b)
        return { name = "onUpdate", type = b.ts("SomeState"), param = "state", log = "State updated" }
      end
    ),
  },
  {
    trigger = "akka-consumer-workflow",
    description = "Akka Consumer of a Workflow's state updates",
    body = consumer_body(
      function(b)
        return "@Consume.FromWorkflow(value = " .. b.ts("SomeWorkflow") .. ".class)"
      end,
      function(b)
        return { name = "onUpdate", type = b.ts("SomeState"), param = "state", log = "State updated" }
      end
    ),
  },
  {
    trigger = "akka-consumer-service-stream",
    description = "Akka Consumer of another service's event stream",
    body = consumer_body(
      function(b)
        return '@Consume.FromServiceStream(service = "'
          .. b.ts("service")
          .. '", id = "'
          .. b.ts("stream-id")
          .. '")'
      end,
      function(b)
        return { name = "onEvent", type = b.ts("SomeEvent"), param = "event", log = "Received event" }
      end
    ),
  },
  {
    trigger = "akka-consumer-topic",
    description = "Akka Consumer of a broker topic (PubSub or Kafka)",
    body = consumer_body(
      function(b)
        return '@Consume.FromTopic("' .. b.ts("topic-name") .. '")'
      end,
      function(b)
        return { name = "onMessage", type = b.ts("SomeMessage"), param = "message", log = "Received message" }
      end
    ),
  },
}

function M.new(opts)
  return setmetatable({ opts = opts or {} }, { __index = M })
end

function M:enabled()
  return vim.bo.filetype == "java"
end

function M:get_completions(_, callback)
  local class_file = vim.fn.expand("%:t:r")
  local ctx = {
    package = package_for_buffer(),
    class_file = class_file ~= "" and class_file or nil,
  }

  local items = {}
  for _, spec in ipairs(specs) do
    items[#items + 1] = {
      label = spec.trigger,
      kind = types.CompletionItemKind.Snippet,
      insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
      insertText = spec.body(ctx),
      documentation = { kind = "markdown", value = spec.description },
    }
  end

  callback({
    is_incomplete_forward = false,
    is_incomplete_backward = false,
    items = items,
  })

  return function() end
end

return M
