// //// <https://json-schema.org/>
// ////
// //// <https://datatracker.ietf.org/doc/html/draft-bhutton-json-schema-00>

// import gleam/bool
// import gleam/dict.{type Dict}
// import gleam/dynamic/decode.{type Dynamic, DecodeError}
// import gleam/json.{type Json}
// import gleam/list
// import gleam/option.{type Option, None, Some}
// import gleam/result
// import gleam/set.{type Set}
// import gleam/string
// import justin

// pub type RootSchema {
//   RootSchema(definitions: List(#(String, Schema)), schema: Schema)
// }

// pub type Type {
//   /// `true` or `false`
//   Boolean
//   /// JSON strings
//   String
//   /// JSON numbers
//   Number
//   /// JSON integers
//   Integer
//   /// JSON arrays
//   ArrayType
//   /// JSON objects
//   ObjectType
//   /// JSON null values
//   Null
// }

// pub type Schema {
//   /// Any value. The empty form is like a Java Object or TypeScript any.
//   Empty(metadata: List(#(String, Dynamic)))
//   /// A simple built-in type. The type form is like a Java or TypeScript
//   /// primitive type.
//   Type(nullable: Bool, metadata: List(#(String, Dynamic)), type_: Type)
//   /// One of a fixed set of strings. The enum form is like a Java or TypeScript
//   /// enum.
//   Enum(
//     nullable: Bool,
//     metadata: List(#(String, Dynamic)),
//     variants: List(String),
//   )
//   // The properties form is like a Java class or TypeScript interface.
//   Object(
//     nullable: Bool,
//     metadata: List(#(String, Dynamic)),
//     schema: ObjectSchema,
//   )
//   /// A sequence of some other form. The items form is like a Java `List<T>`
//   /// or TypeScript `T[]`.
//   Array(nullable: Bool, metadata: List(#(String, Dynamic)), items: Schema)
//   /// A reference to another schema definition
//   Ref(nullable: Bool, metadata: List(#(String, Dynamic)), ref: String)
//   /// A schema that can be one of multiple schemas
//   OneOf(
//     nullable: Bool,
//     metadata: List(#(String, Dynamic)),
//     schemas: List(Schema),
//   )
//   /// A schema that must be all of multiple schemas
//   AllOf(
//     nullable: Bool,
//     metadata: List(#(String, Dynamic)),
//     schemas: List(Schema),
//   )
//   /// A schema that can be any of multiple schemas
//   AnyOf(
//     nullable: Bool,
//     metadata: List(#(String, Dynamic)),
//     schemas: List(Schema),
//   )
//   /// A schema that must not match the given schema
//   Not(nullable: Bool, metadata: List(#(String, Dynamic)), schema: Schema)
// }

// pub type ObjectSchema {
//   ObjectSchema(
//     properties: List(#(String, Schema)),
//     required: List(String),
//     additional_properties: Option(Schema),
//     pattern_properties: List(#(String, Schema)),
//   )
// }

// pub fn to_json(schema: RootSchema) -> Json {
//   let properties = schema_to_json(schema.schema)
//   let properties = case schema.definitions {
//     [] -> properties
//     definitions -> {
//       let definitions =
//         list.map(definitions, fn(definition) {
//           #(definition.0, json.object(schema_to_json(definition.1)))
//         })
//       [#("$defs", json.object(definitions)), ..properties]
//     }
//   }

//   json.object(properties)
// }

// pub fn object_schema_to_json(schema: ObjectSchema) -> List(#(String, Json)) {
//   let props_json = fn(props: List(#(String, Schema))) {
//     json.object(
//       list.map(props, fn(property) {
//         #(property.0, json.object(schema_to_json(property.1)))
//       }),
//     )
//   }

//   let ObjectSchema(
//     properties:,
//     required:,
//     additional_properties:,
//     pattern_properties:,
//   ) = schema

//   let data = []

//   let data = case pattern_properties {
//     [] -> data
//     p -> [#("patternProperties", props_json(p)), ..data]
//   }

//   let data = case additional_properties {
//     None -> data
//     Some(schema) -> [
//       #("additionalProperties", json.object(schema_to_json(schema))),
//       ..data
//     ]
//   }

//   let data = case required {
//     [] -> data
//     r -> [#("required", json.array(r, json.string)), ..data]
//   }

//   let data = case properties {
//     [] -> data
//     p -> [#("properties", props_json(p)), ..data]
//   }

//   data
// }

// fn schema_to_json(schema: Schema) -> List(#(String, Json)) {
//   case schema {
//     Empty(metadata:) ->
//       []
//       |> add_metadata(metadata)
//     Ref(nullable:, metadata:, ref:) ->
//       [#("$ref", json.string(ref))]
//       |> add_nullable(nullable)
//       |> add_metadata(metadata)
//     Type(nullable:, metadata:, type_:) ->
//       [#("type", type_to_json(type_))]
//       |> add_nullable(nullable)
//       |> add_metadata(metadata)
//     Enum(nullable:, metadata:, variants:) ->
//       [#("enum", json.array(variants, json.string))]
//       |> add_nullable(nullable)
//       |> add_metadata(metadata)
//     Array(nullable:, metadata:, items:) ->
//       [#("items", json.object(schema_to_json(items)))]
//       |> add_nullable(nullable)
//       |> add_metadata(metadata)
//     Object(nullable:, metadata:, schema:) ->
//       object_schema_to_json(schema)
//       |> add_nullable(nullable)
//       |> add_metadata(metadata)
//     OneOf(nullable:, metadata:, schemas:) ->
//       [
//         #(
//           "oneOf",
//           json.array(schemas, fn(s) { json.object(schema_to_json(s)) }),
//         ),
//       ]
//       |> add_nullable(nullable)
//       |> add_metadata(metadata)
//     AllOf(nullable:, metadata:, schemas:) ->
//       [
//         #(
//           "allOf",
//           json.array(schemas, fn(s) { json.object(schema_to_json(s)) }),
//         ),
//       ]
//       |> add_nullable(nullable)
//       |> add_metadata(metadata)
//     AnyOf(nullable:, metadata:, schemas:) ->
//       [
//         #(
//           "anyOf",
//           json.array(schemas, fn(s) { json.object(schema_to_json(s)) }),
//         ),
//       ]
//       |> add_nullable(nullable)
//       |> add_metadata(metadata)
//     Not(nullable:, metadata:, schema:) ->
//       [#("not", json.object(schema_to_json(schema)))]
//       |> add_nullable(nullable)
//       |> add_metadata(metadata)
//   }
// }

// fn type_to_json(t: Type) -> Json {
//   json.string(case t {
//     Boolean -> "boolean"
//     String -> "string"
//     Number -> "number"
//     Integer -> "integer"
//     ArrayType -> "array"
//     ObjectType -> "object"
//     Null -> "null"
//   })
// }

// pub fn decoder(data: Dynamic) -> Result(RootSchema, List(decode.DecodeError)) {
//   decode.run(data, {
//     use definitions <- decode.then(decode_definitions)
//     use schema <- decode.then(fn(_) { decode.success(Empty([])) })
//     decode.success(RootSchema(definitions, schema))
//   })
// }

// fn decode_definitions(data: Dynamic) -> decode.Decoder(List(#(String, Schema))) {
//   let defs_decoder = {
//     use defs <- decode.field("$defs", decode.dynamic)
//     dict_to_list_decoder(defs)
//   }

//   let definitions_decoder = {
//     use defs <- decode.field("definitions", decode.dynamic)
//     dict_to_list_decoder(defs)
//   }

//   decode.one_of(defs_decoder, or: [definitions_decoder, decode.success([])])
// }

// fn dict_to_list_decoder(
//   data: Dynamic,
// ) -> decode.Decoder(List(#(String, Schema))) {
//   {
//     use dict <- decode.then(decode.dict(decode.string, decode_schema))
//     decode.success(dict.to_list(dict))
//   }
// }

// fn decode_schema(data: Dynamic) -> decode.Decoder(Schema) {
//   decode.one_of(decode_enum_field, or: [
//     decode_ref_field,
//     decode_array_field,
//     decode_object_field,
//     decode_one_of_field,
//     decode_any_of_field,
//     decode_all_of_field,
//     decode_not_field,
//     decode_type_field,
//     decode_empty(),
//   ])
// }

// fn decode_enum_field(data: Dynamic) -> decode.Decoder(Schema) {
//   use _ <- decode.field("enum", decode.dynamic)
//   use nullable <- decode.then(get_nullable(data))
//   use metadata <- decode.then(get_metadata(data))
//   use values <- decode.at(["enum"], decode.list(of: decode.string))
//   decode.success(Enum(nullable, metadata, values))
// }

// fn decode_ref_field(data: Dynamic) -> decode.Decoder(Schema) {
//   use _ <- decode.field("$ref", decode.dynamic)
//   use nullable <- decode.then(get_nullable(data))
//   use metadata <- decode.then(get_metadata(data))
//   use ref <- decode.at(["$ref"], decode.string)
//   decode.success(Ref(nullable, metadata, ref))
// }

// fn decode_array_field(data: Dynamic) -> decode.Decoder(Schema) {
//   use _ <- decode.field("items", decode.dynamic)
//   use nullable <- decode.then(get_nullable(data))
//   use metadata <- decode.then(get_metadata(data))
//   use items <- decode.at(["items"], decode_schema)
//   decode.success(Array(nullable, metadata, items))
// }

// fn decode_object_field(data: Dynamic) -> decode.Decoder(Schema) {
//   use _ <- decode.field("properties", decode.dynamic)
//   use nullable <- decode.then(get_nullable(data))
//   use metadata <- decode.then(get_metadata(data))
//   use schema <- decode.then(decode_object_schema(data))
//   decode.success(Object(nullable, metadata, schema))
// }

// fn decode_one_of_field(data: Dynamic) -> decode.Decoder(Schema) {
//   use _ <- decode.field("oneOf", decode.dynamic)
//   use nullable <- decode.then(get_nullable(data))
//   use metadata <- decode.then(get_metadata(data))
//   use schemas <- decode.at(["oneOf"], decode.list(of: decode_schema))
//   decode.success(OneOf(nullable, metadata, schemas))
// }

// fn decode_any_of_field(data: Dynamic) -> decode.Decoder(Schema) {
//   use _ <- decode.field("anyOf", decode.dynamic)
//   use nullable <- decode.then(get_nullable(data))
//   use metadata <- decode.then(get_metadata(data))
//   use schemas <- decode.at(["anyOf"], decode.list(of: decode_schema))
//   decode.success(AnyOf(nullable, metadata, schemas))
// }

// fn decode_all_of_field(data: Dynamic) -> decode.Decoder(Schema) {
//   use _ <- decode.field("allOf", decode.dynamic)
//   use nullable <- decode.then(get_nullable(data))
//   use metadata <- decode.then(get_metadata(data))
//   use schemas <- decode.at(["allOf"], decode.list(of: decode_schema))
//   decode.success(AllOf(nullable, metadata, schemas))
// }

// fn decode_not_field(data: Dynamic) -> decode.Decoder(Schema) {
//   use _ <- decode.field("not", decode.dynamic)
//   use nullable <- decode.then(get_nullable(data))
//   use metadata <- decode.then(get_metadata(data))
//   use schema <- decode.at(["not"], decode_schema)
//   decode.success(Not(nullable, metadata, schema))
// }

// fn decode_type_field(data: Dynamic) -> decode.Decoder(Schema) {
//   use _ <- decode.field("type", decode.dynamic)
//   use nullable <- decode.then(get_nullable(data))
//   use metadata <- decode.then(get_metadata(data))
//   use type_value <- decode.at(["type"], decode_type_value)
//   decode.success(Type(nullable, metadata, type_value))
// }

// fn decode_type_value(data: Dynamic) -> decode.Decoder(Type) {
//   let string_decoder = {
//     use type_str <- decode.then(decode.string)
//     case type_str {
//       "boolean" -> decode.success(Boolean)
//       "string" -> decode.success(String)
//       "number" -> decode.success(Number)
//       "integer" -> decode.success(Integer)
//       "array" -> decode.success(ArrayType)
//       "object" -> decode.success(ObjectType)
//       "null" -> decode.success(Null)
//       _ -> decode.failure(String, "Type")
//     }
//   }

//   let list_decoder = {
//     use types <- decode.then(decode.list(of: decode.string))
//     let contains_null = list.contains(types, "null")
//     case types {
//       // ["null", ..] | [.., "null"] -> decode.success(Null)
//       [t, ..] ->
//         case t {
//           "boolean" -> decode.success(Boolean)
//           "string" -> decode.success(String)
//           "number" -> decode.success(Number)
//           "integer" -> decode.success(Integer)
//           "array" -> decode.success(ArrayType)
//           "object" -> decode.success(ObjectType)
//           _ -> decode.success(ObjectType)
//           // Default to object for unknown types
//         }
//       [] -> decode.failure(ObjectType, "Type")
//     }
//   }

//   decode.one_of(string_decoder, or: [list_decoder])
// }

// fn decode_empty() -> decode.Decoder(Schema) {
//   use metadata <- decode.then(get_metadata_raw)
//   decode.success(Empty(metadata))
// }

// pub fn decode_object_schema(data: Dynamic) -> decode.Decoder(ObjectSchema) {
//   {
//     use properties <- decode.then(decode_properties(data))
//     use required <- decode.then(decode_required(data))
//     use additional_properties <- decode.then(decode_additional_properties(data))
//     use pattern_properties <- decode.then(decode_pattern_properties(data))
//     decode.success(ObjectSchema(
//       properties: properties,
//       required: required,
//       additional_properties: additional_properties,
//       pattern_properties: pattern_properties,
//     ))
//   }
// }

// fn decode_properties(data: Dynamic) -> decode.Decoder(List(#(String, Schema))) {
//   decode.optionally_at(["properties"], [], decode_object_as_list(decode_schema))
// }

// fn decode_pattern_properties(
//   data: Dynamic,
// ) -> decode.Decoder(List(#(String, Schema))) {
//   decode.optionally_at(
//     ["patternProperties"],
//     [],
//     decode_object_as_list(decode_schema),
//   )
// }

// fn decode_required(data: Dynamic) -> decode.Decoder(List(String)) {
//   decode.optionally_at(["required"], [], decode.list(of: decode.string))
// }

// fn decode_additional_properties(data: Dynamic) -> decode.Decoder(Option(Schema)) {
//   let true_decoder = {
//     use b <- decode.then(decode.bool)
//     case b {
//       True -> decode.success(Some(Empty([])))
//       False -> decode.success(None)
//     }
//   }

//   let schema_decoder = {
//     use schema <- decode.then(decode_schema)
//     decode.success(Some(schema))
//   }

//   decode.optionally_at(
//     ["additionalProperties"],
//     Some(Empty([])),
//     decode.one_of(true_decoder, or: [schema_decoder]),
//   )
// }

// fn decode_object_as_list(
//   inner: fn(Dynamic) -> decode.Decoder(t),
// ) -> decode.Decoder(List(#(String, t))) {
//   {
//     use dict <- decode.then(decode.dict(decode.string, decode.dynamic))
//     use pairs <- decode.then({
//       use _ <- decode.success
//       dict
//       |> dict.to_list
//       |> list.try_fold([], fn(acc, pair) {
//         let #(key, value) = pair
//         case decode.run(value, inner(value)) {
//           Ok(decoded) -> Ok([#(key, decoded), ..acc])
//           Error(e) -> Error(e)
//         }
//       })
//     })
//     decode.success(pairs)
//   }
// }

// fn get_metadata(data: Dynamic) -> decode.Decoder(List(#(String, Dynamic))) {
//   get_metadata_raw
// }

// fn get_metadata_raw() -> decode.Decoder(List(#(String, Dynamic))) {
//   // This is a simplification - we should extract all non-standard fields
//   // In a real implementation, you'd create a dict decoder and filter out standard fields
//   decode.success([])
// }

// fn get_nullable(data: Dynamic) -> decode.Decoder(Bool) {
//   decode.one_of(
//     {
//       use nullable <- decode.field("nullable", decode.bool)
//       decode.success(nullable)
//     },
//     or: [
//       {
//         use types <- decode.field("type", decode.list(of: decode.string))
//         decode.success(list.contains(types, "null"))
//       },
//       decode.success(False),
//     ],
//   )
// }

// fn metadata_value_to_json(data: Dynamic) -> Json {
//   let decoder =
//     decode.one_of(decode.string |> decode.map(json.string), or: [
//       decode.int |> decode.map(json.int),
//       decode.float |> decode.map(json.float),
//       decode.bool |> decode.map(json.bool),
//     ])

//   case decode.run(data, decoder) {
//     Ok(value) -> value
//     Error(_) -> json.string(string.inspect(data))
//   }
// }

// fn add_metadata(
//   data: List(#(String, Json)),
//   metadata: List(#(String, Dynamic)),
// ) -> List(#(String, Json)) {
//   list.fold(metadata, data, fn(acc, meta) {
//     [#(meta.0, metadata_value_to_json(meta.1)), ..acc]
//   })
// }

// fn add_nullable(
//   data: List(#(String, Json)),
//   nullable: Bool,
// ) -> List(#(String, Json)) {
//   case nullable {
//     False -> data
//     True -> [#("nullable", json.bool(True)), ..data]
//   }
// }

// pub opaque type Generator {
//   Generator(
//     generate_decoders: Bool,
//     generate_encoders: Bool,
//     dynamic_used: Bool,
//     option_used: Bool,
//     dict_used: Bool,
//     required_properties_used: Bool,
//     types: Dict(String, String),
//     functions: Dict(String, String),
//     root_name: String,
//     constructors: Set(String),
//   )
// }

// pub fn codegen() -> Generator {
//   Generator(
//     dynamic_used: False,
//     option_used: False,
//     dict_used: False,
//     required_properties_used: False,
//     generate_decoders: False,
//     generate_encoders: False,
//     types: dict.new(),
//     functions: dict.new(),
//     root_name: "Data",
//     constructors: set.new(),
//   )
// }

// pub fn root_name(gen: Generator, root_name: String) -> Generator {
//   Generator(..gen, root_name:)
// }

// pub fn generate_encoders(gen: Generator, x: Bool) -> Generator {
//   Generator(..gen, generate_encoders: x)
// }

// pub fn generate_decoders(gen: Generator, x: Bool) -> Generator {
//   Generator(..gen, generate_decoders: x)
// }

// type Out {
//   Out(src: String, type_name: String)
// }

// pub type CodegenError {
//   CannotConvertEmptyToJsonError
//   EmptyEnumError
//   DuplicatePropertyError(
//     type_name: String,
//     constructor_name: String,
//     property_name: String,
//   )
//   DuplicateConstructorError(name: String)
//   DuplicateTypeError(name: String)
//   DuplicateFunctionError(name: String)
// }

// pub fn generate(
//   gen: Generator,
//   schema: RootSchema,
// ) -> Result(String, CodegenError) {
//   let root = justin.pascal_case(gen.root_name)

//   use gen <- result.try(gen_types(gen, root, schema))

//   use gen <- result.try(case gen.generate_decoders {
//     True -> gen_decoders(gen, root, schema)
//     False -> Ok(gen)
//   })

//   use gen <- result.map(case gen.generate_encoders {
//     True -> gen_encoders(gen, root, schema)
//     False -> Ok(gen)
//   })

//   gen_to_string(gen)
// }

// fn gen_types(
//   gen: Generator,
//   _root: String,
//   schema: RootSchema,
// ) -> Result(Generator, CodegenError) {
//   list.try_fold(schema.definitions, gen, fn(gen, def) {
//     gen_type(gen, def.0, def.1)
//   })
// }

// fn gen_encoders(
//   gen: Generator,
//   root: String,
//   schema: RootSchema,
// ) -> Result(Generator, CodegenError) {
//   gen_add_encoder(gen, root, schema.schema)
// }

// fn gen_decoders(
//   gen: Generator,
//   root: String,
//   schema: RootSchema,
// ) -> Result(Generator, CodegenError) {
//   gen_add_decoder(gen, root, schema.schema)
// }

// fn gen_type(
//   gen: Generator,
//   name: String,
//   schema: Schema,
// ) -> Result(Generator, CodegenError) {
//   let name = justin.pascal_case(name)
//   case schema {
//     Empty(..) -> Ok(Generator(..gen, dynamic_used: True))
//     Ref(nullable:, ..) -> Ok(gen_register_nullable(gen, nullable))
//     Type(nullable:, ..) -> Ok(gen_register_nullable(gen, nullable))

//     Enum(nullable:, variants:, ..) -> {
//       let gen = gen_register_nullable(gen, nullable)
//       gen_enum_type_string(gen, name, variants)
//     }

//     Object(schema:, nullable:, ..) -> {
//       let gen = gen_register_nullable(gen, nullable)
//       gen_register_object(gen, name, schema)
//     }

//     Array(nullable:, items:, ..) -> {
//       let gen = gen_register_nullable(gen, nullable)
//       gen_type(gen, name <> "Item", items)
//     }

//     OneOf(nullable:, schemas:, ..)
//     | AnyOf(nullable:, schemas:, ..)
//     | AllOf(nullable:, schemas:, ..) -> {
//       let gen = gen_register_nullable(gen, nullable)
//       list.try_fold(schemas, gen, fn(gen, schema) {
//         gen_type(gen, name <> "Element", schema)
//       })
//     }

//     Not(nullable:, schema:, ..) -> {
//       let gen = gen_register_nullable(gen, nullable)
//       gen_type(gen, name <> "Not", schema)
//     }
//   }
// }

// fn type_name(schema: Schema, name: String) -> String {
//   let nullable = case schema {
//     Empty(..) -> False
//     Not(nullable:, ..)
//     | Array(nullable:, ..)
//     | Enum(nullable:, ..)
//     | OneOf(nullable:, ..)
//     | AnyOf(nullable:, ..)
//     | AllOf(nullable:, ..)
//     | Object(nullable:, ..)
//     | Ref(nullable:, ..)
//     | Type(nullable:, ..) -> nullable
//   }
//   let name = case schema {
//     Enum(..) | Object(..) -> name

//     Ref(ref:, ..) -> {
//       case string.split(ref, "/") {
//         ["#", "definitions", def_name] -> justin.pascal_case(def_name)
//         ["#", "$defs", def_name] -> justin.pascal_case(def_name)
//         _ -> "Unknown"
//       }
//     }

//     Array(items:, ..) -> "List(" <> type_name(items, name <> "Item") <> ")"
//     Empty(..) -> "dynamic.Dynamic"

//     Type(type_:, ..) ->
//       case type_ {
//         Boolean -> "Bool"
//         String -> "String"
//         Number | Integer -> "Int"
//         ArrayType -> "List(dynamic.Dynamic)"
//         ObjectType -> "Dict(String, dynamic.Dynamic)"
//         Null -> "Nil"
//       }

//     OneOf(schemas:, ..) | AnyOf(schemas:, ..) | AllOf(schemas:, ..) -> {
//       name
//       // Handle complex unions as a custom type
//     }

//     Not(schema:, ..) -> type_name(schema, name <> "Not")
//   }

//   case nullable {
//     True -> "option.Option(" <> name <> ")"
//     False -> name
//   }
// }

// fn gen_register_object(
//   gen: Generator,
//   name: String,
//   schema: ObjectSchema,
// ) -> Result(Generator, CodegenError) {
//   use _ <- result.try(ensure_no_duplicate_properties(schema, name, name))

//   use #(gen, src) <- result.try(type_variant(gen, name, schema))

//   let src = "pub type " <> name <> " {\n" <> src <> "\n}"
//   let type_name = name
//   gen_add_type(gen, type_name, src)
// }

// fn ensure_no_duplicate_properties(
//   schema: ObjectSchema,
//   type_name: String,
//   constructor_name: String,
// ) -> Result(Nil, CodegenError) {
//   let names = schema.properties
//   let recorded = set.new()

//   list.try_fold(names, recorded, fn(recorded, pair) {
//     let field_name = justin.snake_case(pair.0)
//     let before = set.size(recorded)
//     let recorded = set.insert(recorded, field_name)
//     case before == set.size(recorded) {
//       False -> Ok(recorded)
//       True ->
//         Error(DuplicatePropertyError(type_name, constructor_name, field_name))
//     }
//   })
//   |> result.replace(Nil)
// }

// fn type_variant(
//   gen: Generator,
//   name: String,
//   schema: ObjectSchema,
// ) -> Result(#(Generator, String), CodegenError) {
//   let gen = case schema.required {
//     [] -> gen
//     _ -> Generator(..gen, required_properties_used: True)
//   }

//   let ObjectSchema(
//     properties:,
//     required:,
//     additional_properties: _,
//     pattern_properties: _,
//   ) = schema

//   use gen <- result.try(
//     list.try_fold(properties, gen, fn(gen, prop) {
//       gen_type(gen, name <> justin.pascal_case(prop.0), prop.1)
//     }),
//   )

//   let property_is_required = fn(prop_name) {
//     list.contains(required, prop_name)
//   }

//   let properties =
//     properties
//     |> list.map(fn(p) {
//       let is_required = property_is_required(p.0)
//       #(p.0, p.1, !is_required)
//     })
//     |> list.sort(fn(a, b) { string.compare(a.0, b.0) })
//     |> list.map(fn(p) {
//       let n = justin.snake_case(p.0)
//       let type_n = type_name(p.1, name <> justin.pascal_case(p.0))
//       let type_n = case p.2 {
//         True -> "option.Option(" <> type_n <> ")"
//         False -> type_n
//       }
//       "    " <> n <> ": " <> type_n
//     })
//     |> string.join(",\n")

//   use gen <- result.try(ensure_constructor_unique(gen, name))

//   let src = "  " <> name <> "(\n" <> properties <> ",\n  )"

//   Ok(#(gen, src))
// }

// fn ensure_constructor_unique(
//   gen: Generator,
//   name: String,
// ) -> Result(Generator, CodegenError) {
//   let before = set.size(gen.constructors)
//   let constructors = set.insert(gen.constructors, name)
//   case before == set.size(constructors) {
//     False -> Ok(Generator(..gen, constructors:))
//     True -> Error(DuplicateConstructorError(name))
//   }
// }

// fn gen_enum_type_string(
//   gen: Generator,
//   name: String,
//   variants: List(String),
// ) -> Result(Generator, CodegenError) {
//   use <- bool.guard(when: variants == [], return: Error(EmptyEnumError))

//   let variants =
//     variants
//     |> list.map(fn(v) { "  " <> justin.pascal_case(v) <> "\n" })
//     |> string.join("")
//   let src = "pub type " <> name <> " {\n" <> variants <> "}"
//   gen_add_type(gen, name, src)
// }

// fn gen_register_nullable(gen: Generator, nullable: Bool) -> Generator {
//   case nullable {
//     False -> gen
//     True -> Generator(..gen, option_used: True)
//   }
// }

// fn gen_add_encoder(
//   gen: Generator,
//   name: String,
//   schema: Schema,
// ) -> Result(Generator, CodegenError) {
//   use out <- result.try(en_schema(schema, Some("data"), name))
//   let name = justin.snake_case(name) <> "_to_json"
//   let src =
//     "pub fn "
//     <> name
//     <> "(data: "
//     <> out.type_name
//     <> ") -> json.Json {\n  "
//     <> out.src
//     <> "\n}"

//   gen_add_function(gen, name, src)
// }

// fn gen_add_decoder(
//   gen: Generator,
//   name: String,
//   schema: Schema,
// ) -> Result(Generator, CodegenError) {
//   use out <- result.try(de_schema(schema, name))
//   let fn_name = justin.snake_case(name) <> "_decoder"
//   let src =
//     "pub fn "
//     <> fn_name
//     <> "() -> decode.Decoder("
//     <> out.type_name
//     <> ") {\n  "
//     <> out.src
//     <> "\n}"

//   gen_add_function(gen, name, src)
// }

// fn gen_add_function(
//   gen: Generator,
//   name: String,
//   body: String,
// ) -> Result(Generator, CodegenError) {
//   let before = dict.size(gen.functions)
//   let functions = dict.insert(gen.functions, name, body)
//   case dict.size(functions) == before {
//     False -> Ok(Generator(..gen, functions:))
//     True -> Error(DuplicateFunctionError(name))
//   }
// }

// fn gen_add_type(
//   gen: Generator,
//   name: String,
//   body: String,
// ) -> Result(Generator, CodegenError) {
//   let before = dict.size(gen.types)
//   let types = dict.insert(gen.types, name, body)
//   case dict.size(types) == before {
//     False -> Ok(Generator(..gen, types:))
//     True -> Error(DuplicateTypeError(name))
//   }
// }

// fn gen_to_string(gen: Generator) -> String {
//   let imp = fn(used, module) {
//     case used {
//       True -> [module]
//       False -> []
//     }
//   }

//   let imports =
//     [
//       imp(gen.generate_decoders, "gleam/dynamic/decode"),
//       imp(gen.dict_used, "gleam/dict"),
//       imp(gen.dynamic_used, "gleam/dynamic"),
//       imp(gen.generate_encoders, "gleam/json"),
//       imp(gen.option_used, "gleam/option"),
//     ]
//     |> list.flatten
//     |> list.map(fn(m) { "import " <> m })
//     |> string.join("\n")

//   let defs = fn(items: Dict(String, String)) -> String {
//     items
//     |> dict.to_list
//     |> list.sort(fn(a, b) { string.compare(a.0, b.0) })
//     |> list.map(fn(a) { a.1 })
//     |> string.join("\n\n")
//   }

//   let block = fn(s) {
//     case s {
//       "" -> []
//       _ -> [s]
//     }
//   }

//   let helper__optional_property = case
//     gen.generate_encoders && gen.required_properties_used
//   {
//     False -> []
//     True -> [
//       "fn helper__optional_property(\n  object: List(#(String, json.Json)),\n  key: String,\n  value: option.Option(a),\n  to_json: fn(a) -> json.Json,\n) -> List(#(String, json.Json)) {\n  case value {\n    option.Some(value) -> [#(key, to_json(value)), ..object]\n    option.None -> object\n  }\n}",
//     ]
//   }

//   let helper__dict_to_json = case gen.generate_encoders && gen.dict_used {
//     False -> []
//     True -> [
//       "fn helper__dict_to_json(\n  data: dict.Dict(String, t),\n  to_json: fn(t) -> json.Json,\n) -> json.Json {\n  data\n  |> dict.to_list\n  |> list.map(fn(pair) { #(pair.0, to_json(pair.1)) })\n  |> json.object\n}",
//     ]
//   }

//   [
//     block(imports),
//     block(defs(gen.types)),
//     block(defs(gen.functions)),
//     helper__dict_to_json,
//     helper__optional_property,
//   ]
//   |> list.flatten
//   |> string.join("\n\n")
// }

// fn en_schema(
//   schema: Schema,
//   data: Option(String),
//   name: String,
// ) -> Result(Out, CodegenError) {
//   case schema {
//     OneOf(nullable:, metadata: _, schemas:)
//     | AnyOf(nullable:, metadata: _, schemas:)
//     | AllOf(nullable:, metadata: _, schemas:) ->
//       en_composite_schema(schemas, nullable, data, name)
//     Array(nullable:, metadata: _, items:) ->
//       en_array(items, nullable, data, name <> "Item")
//     Empty(..) -> Error(CannotConvertEmptyToJsonError)
//     Enum(nullable:, variants:, metadata: _) ->
//       en_enum_string(variants, nullable, data, name)
//     Object(nullable:, schema:, metadata: _) ->
//       en_object_schema(schema, nullable, pro_data_name(data), name)
//     Ref(nullable:, metadata: _, ref:) -> en_ref(ref, data, nullable)
//     Type(type_:, nullable:, metadata: _) -> Ok(en_type(type_, nullable, data))
//     Not(nullable:, schema:, metadata: _) ->
//       en_schema(schema, data, name <> "Not")
//   }
// }

// fn en_ref(
//   ref: String,
//   data: Option(String),
//   nullable: Bool,
// ) -> Result(Out, CodegenError) {
//   let name = case string.split(ref, "/") {
//     ["#", "definitions", def_name] -> def_name
//     ["#", "$defs", def_name] -> def_name
//     _ -> "unknown"
//   }

//   let src = justin.snake_case(name) <> "_to_json"
//   let src = case data, nullable {
//     None, False -> src
//     None, True -> "json.nullable(_, " <> src <> ")"
//     Some(data), False -> src <> "(" <> data <> ")"
//     Some(data), True -> "json.nullable(" <> data <> ", " <> src <> ")"
//   }

//   let type_name = justin.pascal_case(name)
//   let type_name = case nullable {
//     False -> type_name
//     True -> "option.Option(" <> type_name <> ")"
//   }

//   Ok(Out(src:, type_name:))
// }

// fn de_ref(ref: String, nullable: Bool) -> Result(Out, CodegenError) {
//   let name = case string.split(ref, "/") {
//     ["#", "definitions", def_name] -> def_name
//     ["#", "$defs", def_name] -> def_name
//     _ -> "unknown"
//   }

//   let src = justin.snake_case(name) <> "_decoder()"
//   let src = case nullable {
//     False -> src
//     True -> "decode.optional(" <> src <> ")"
//   }

//   let type_name = justin.pascal_case(name)
//   let type_name = case nullable {
//     False -> type_name
//     True -> "option.Option(" <> type_name <> ")"
//   }

//   Ok(Out(src:, type_name:))
// }

// type PropertyDataName {
//   PropertyDataNone
//   PropertyDataDirect
//   PropertyDataAccess(String)
// }

// fn pro_data_name(name: Option(String)) -> PropertyDataName {
//   case name {
//     None -> PropertyDataNone
//     Some(n) -> PropertyDataAccess(n)
//   }
// }

// fn de_schema(schema: Schema, name: String) -> Result(Out, CodegenError) {
//   case schema {
//     OneOf(nullable:, metadata: _, schemas:)
//     | AnyOf(nullable:, metadata: _, schemas:)
//     | AllOf(nullable:, metadata: _, schemas:) ->
//       de_composite_schema(schemas, nullable, name)
//     Array(nullable:, metadata: _, items:) ->
//       de_array(items, nullable, name <> "Item")
//     Empty(..) -> Ok(Out("decode.dynamic", "dynamic.Dynamic"))
//     Enum(nullable:, variants:, metadata: _) -> de_enum(variants, nullable, name)
//     Object(nullable:, schema:, metadata: _) ->
//       de_object_schema(schema, nullable, name)
//     Ref(nullable:, metadata: _, ref:) -> de_ref(ref, nullable)
//     Type(type_:, nullable:, metadata: _) -> Ok(de_type(type_, nullable))
//     Not(nullable:, schema:, metadata: _) -> de_schema(schema, name <> "Not")
//   }
// }

// fn de_composite_schema(
//   schemas: List(Schema),
//   nullable: Bool,
//   name: String,
// ) -> Result(Out, CodegenError) {
//   // This is simplified - in a real implementation you'd need to handle the
//   // differences between oneOf, anyOf, and allOf more carefully
//   use first_schema <- result.try(case schemas {
//     [first, ..] -> Ok(first)
//     [] -> Error(EmptyEnumError)
//   })

//   de_schema(first_schema, name)
// }

// fn en_composite_schema(
//   schemas: List(Schema),
//   nullable: Bool,
//   data: Option(String),
//   name: String,
// ) -> Result(Out, CodegenError) {
//   // This is simplified - in a real implementation you'd need to handle the
//   // differences between oneOf, anyOf, and allOf more carefully
//   use first_schema <- result.try(case schemas {
//     [first, ..] -> Ok(first)
//     [] -> Error(EmptyEnumError)
//   })

//   en_schema(first_schema, data, name)
// }

// fn de_object_schema(
//   schema: ObjectSchema,
//   nullable: Bool,
//   name: String,
// ) -> Result(Out, CodegenError) {
//   let ObjectSchema(
//     properties:,
//     required:,
//     additional_properties: _,
//     pattern_properties: _,
//   ) = schema

//   use properties <- result.try(
//     list.try_map(properties, fn(prop) {
//       use s <- result.map(de_schema(prop.1, name <> justin.pascal_case(prop.0)))
//       let is_required = list.contains(required, prop.0)
//       #(prop.0, s, !is_required)
//     }),
//   )

//   let params =
//     properties
//     |> list.map(fn(n) {
//       let name = justin.snake_case(n.0)
//       "    use " <> name <> " <- decode.field"
//     })
//     |> string.join("\n")

//   let fields =
//     properties
//     |> list.map(fn(p) {
//       let field = case p.2 {
//         True -> "optional_field"
//         False -> "field"
//       }
//       "\"" <> p.0 <> "\", " <> { p.1 }.src
//     })
//     |> string.join("\n    ")

//   let keys =
//     properties
//     |> list.map(fn(n) { justin.snake_case(n.0) <> ":" })
//     |> string.join(", ")

//   let src =
//     "{\n"
//     <> params
//     <> "(\"name\", decode.string)\n    "
//     <> "decode.success("
//     <> name
//     <> "("
//     <> keys
//     <> "))\n  }\n"

//   Ok(de_nullable(src, name, nullable))
// }

// fn en_object_schema(
//   schema: ObjectSchema,
//   nullable: Bool,
//   data: PropertyDataName,
//   name: String,
// ) -> Result(Out, CodegenError) {
//   let ObjectSchema(
//     properties:,
//     required:,
//     additional_properties: _,
//     pattern_properties: _,
//   ) = schema

//   let property_data = fn(field_name) {
//     let field_name = justin.snake_case(field_name)
//     case data {
//       PropertyDataDirect -> field_name
//       PropertyDataAccess(name) if !nullable -> name <> "." <> field_name
//       _ -> "data." <> field_name
//     }
//   }

//   use properties <- result.try(
//     list.try_map(properties, fn(p) {
//       let name = name <> justin.pascal_case(p.0)
//       let data = property_data(p.0)
//       use out <- result.map(en_schema(p.1, Some(data), name))
//       #(p.0, out.src)
//     }),
//   )

//   let properties =
//     properties
//     |> list.map(fn(p) { "\n    #(\"" <> p.0 <> "\", " <> p.1 <> ")," })

//   let src = case properties {
//     [] -> "[]"
//     p -> "[" <> string.concat(p) <> "\n  ]"
//   }

//   let src = "json.object(" <> src <> ")"

//   let src = case nullable {
//     True -> {
//       let data = case data {
//         PropertyDataAccess(name) -> name
//         PropertyDataDirect | PropertyDataNone -> "data"
//       }
//       "case "
//       <> data
//       <> " {\n    option.Some(data) -> "
//       <> src
//       <> "\n    option.None -> json.null()\n  }"
//     }
//     False -> src
//   }

//   let src = case data {
//     PropertyDataNone -> "fn(data) { " <> src <> " }"
//     _ -> src
//   }

//   let type_name = case nullable {
//     True -> "option.Option(" <> name <> ")"
//     False -> name
//   }

//   Ok(Out(src:, type_name:))
// }

// fn en_array(
//   schema: Schema,
//   nullable: Bool,
//   data: Option(String),
//   position_name: String,
// ) -> Result(Out, CodegenError) {
//   use Out(src:, type_name:) <- result.try(en_schema(schema, None, position_name))
//   let type_name = "List(" <> type_name <> ")"
//   let data = option.unwrap(data, "_")
//   case nullable {
//     False -> {
//       let src = "json.array(" <> data <> ", " <> src <> ")"
//       Ok(Out(src:, type_name:))
//     }
//     True -> {
//       let type_name = "option.Option(" <> type_name <> ")"
//       let src = "json.array(_, " <> src <> ")"
//       let src = "json.nullable(" <> data <> ", " <> src <> ")"
//       Ok(Out(src:, type_name:))
//     }
//   }
// }

// fn en_enum_string(
//   variants: List(String),
//   nullable: Bool,
//   data: Option(String),
//   position_name: String,
// ) -> Result(Out, CodegenError) {
//   let type_name = position_name

//   let src = "json.string(case " <> option.unwrap(data, "data") <> " {\n"
//   let variants =
//     variants
//     |> list.map(fn(v) {
//       "    " <> justin.pascal_case(v) <> " -> \"" <> v <> "\"\n"
//     })
//     |> string.concat
//   let src = src <> variants <> "  })"

//   let src = case nullable || data == None {
//     True -> "fn(data) { " <> src <> " }"
//     False -> src
//   }

//   let out = case nullable {
//     True -> {
//       let type_name = "option.Option(" <> type_name <> ")"
//       let src = case data {
//         Some(data) -> "json.nullable(" <> data <> ", " <> src <> ")"
//         None -> "json.nullable(_, " <> src <> ")"
//       }
//       Out(src:, type_name:)
//     }
//     False -> Out(src:, type_name:)
//   }
//   Ok(out)
// }

// fn de_array(
//   schema: Schema,
//   nullable: Bool,
//   position_name: String,
// ) -> Result(Out, CodegenError) {
//   use Out(src:, type_name:) <- result.try(de_schema(schema, position_name))
//   let type_name = "List(" <> type_name <> ")"
//   let src = "decode.list(of: " <> src <> ")"
//   Ok(de_nullable(src, type_name, nullable))
// }

// fn de_enum(
//   variants: List(String),
//   nullable: Bool,
//   position_name: String,
// ) -> Result(Out, CodegenError) {
//   let type_name = position_name
//   let src = "decode.then(decode.string, fn(s) {\n    case s {\n"
//   let variants =
//     list.map(variants, fn(v) {
//       "      \""
//       <> v
//       <> "\" -> decode.success("
//       <> justin.pascal_case(v)
//       <> ")\n"
//     })
//   let src = src <> string.concat(variants)
//   let src = src <> "      _ -> decode.failure(\"" <> type_name <> "\", \"\")\n"
//   let src = src <> "    }\n  })"
//   Ok(de_nullable(src, type_name, nullable))
// }

// fn de_type(t: Type, nullable: Bool) -> Out {
//   let #(src, type_name) = case t {
//     Boolean -> #("decode.bool", "Bool")
//     String -> #("decode.string", "String")
//     Number | Integer -> #("decode.int", "Int")
//     ArrayType -> #("decode.list(of: decode.dynamic)", "List(dynamic.Dynamic)")
//     ObjectType -> #(
//       "decode.dict(decode.string, decode.dynamic)",
//       "dict.Dict(String, dynamic.Dynamic)",
//     )
//     Null -> #("decode.success(Nil)", "Nil")
//   }
//   de_nullable(src, type_name, nullable)
// }

// fn en_type(t: Type, nullable: Bool, data: Option(String)) -> Out {
//   let #(src, type_name) = case t {
//     Boolean -> #("json.bool", "Bool")
//     String -> #("json.string", "String")
//     Number | Integer -> #("json.int", "Int")
//     ArrayType -> #("json.array(_, json.string)", "List(String)")
//     ObjectType -> #("json.object", "dict.Dict(String, json.Json)")
//     Null -> #("fn(_) { json.null() }", "Nil")
//   }
//   en_nullable(src, type_name, nullable, data)
// }

// fn en_nullable(
//   src: String,
//   type_name: String,
//   nullable: Bool,
//   data: Option(String),
// ) -> Out {
//   case nullable {
//     True -> {
//       let type_name = "option.Option(" <> type_name <> ")"
//       let src = case data {
//         Some(data) -> "json.nullable(" <> data <> ", " <> src <> ")"
//         None -> "json.nullable(_, " <> src <> ")"
//       }
//       Out(src:, type_name:)
//     }
//     False -> {
//       let src = case data {
//         Some(data) -> src <> "(" <> data <> ")"
//         None -> src
//       }
//       Out(src:, type_name:)
//     }
//   }
// }

// fn de_nullable(src: String, type_name: String, nullable: Bool) -> Out {
//   case nullable {
//     True -> {
//       let type_name = "option.Option(" <> type_name <> ")"
//       let src = "decode.optional(" <> src <> ")"
//       Out(src:, type_name:)
//     }
//     False -> Out(src:, type_name:)
//   }
// }
