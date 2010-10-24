
macro :error_table do
	%{
		<table style="width:100%;">
			<tr>
				<th style="width:30%">Error Message</th>
				<th>Description</th>
			</tr>
			#{value}
		</table>
	}
end

macro :ref_error do
	error, description = params
	%{
		<tr>
			<td>#{error}</td>
			<td>#{description}</td>
		</tr>
	}
end

macro :"%>" do
	interpret "=>[#m_#{value.gsub(/[^a-z0-1_-]/, '_')}|code[#{value}]] macro"
end

macro :"#>" do
	interpret "=>[#c_#{value}|code[#{value}]] command"
end

macro :"$>" do
	interpret "=>[#s_#{value.gsub(/\./, '_')}|code[#{value}]] setting"
end

macro :default do
	%{<strong>Default Value:</strong> <code>#{value}</code>}
end

macro :parameters do
	interpret %{
		section[
			@title[#{@name.to_s[0..0].upcase+@name.to_s[1..@name.to_s.length-1]}]
			@notoc[true]

		<table style="width:100%;">
			<tr>
				<th style="width:30%">#{@name.to_s[0..0].upcase+@name.to_s[1..@name.to_s.length-2]}</th>
				<th>Description</th>
			</tr>
#{value}
		</table>
		]
	}
end

macro :option do
	ident = param(0)
	desc = param(1)
	%{
		<tr>
			<td><code>-#{ident[0..0]}</code> (<code>--#{ident}</code>)</td>
			<td>
#{desc}
			</td>
		</tr>
	}
end

macro :long_option do
	ident = param(0)
	desc = param(1)
	%{
		<tr>
			<td><code>--#{ident}</code></td>
			<td>
#{desc}
			</td>
		</tr>
	}
end

macro :values do
	%{*Possible Values:* @#{value}@}
end

macro :example do
	%{<p><strong>Example:</strong> <code>#{value}</code></p>}
end

macro :block_example do
	interpret %{
		div[@class[example]
			p[strong[Example]]
			highlight[=html|
#{value}
			=]
		]
	}
end

macro :examples do
	%{
<div class="examples">
<p><strong>Examples:</strong></p> 
#{value.split("\n").map{|i| "<code>#{i}</code><br />"}.to_s}
</div>
	}
end

macro :aliases do
	%{<strong>Aliases:</strong> <code>#{value}</code>}
end

macro :ref_macro do
	m_name = raw_attr(:n)
	m_value = raw_attr(:desc)
	m_params = "parameters[#{raw_attr(:params)}]" if raw_attr(:params)
	m_attrs = "attributes[#{raw_attr(:attrs)}]" if raw_attr(:attrs)
	m_examples = "examples[#{raw_attr(:examples)}]" if raw_attr(:examples)
	m_example = "example[#{raw_attr(:example)}]" if raw_attr(:example)
	m_block_example = "block_example[#{raw_attr(:block_example)}]" if raw_attr(:block_example)
	m_aliases = "aliases[#{raw_attr(:aliases)}]" if raw_attr(:aliases)
	m_remarks = %{section[
		@title[Remarks]
		@notoc[:true]
			txt[
#{raw_attr(:remarks)}
			]
		]} if raw_attr(:remarks)
	interpret %{
	section[
		@title[#{m_name}]
		@id[m_#{m_name.gsub(/[^a-z0-1_-]/, '_')}]
		txt[
#{m_value}
		]
#{m_aliases}
#{m_example}
#{m_block_example}
#{m_examples}
#{m_params}
#{m_attrs}
#{m_remarks}
	]
	}
end

macro :ref_config do
	m_name = param(0)
	m_value = param(1)
	default = Glyph::SYSTEM_CONFIG.get(m_name).inspect
	default = "nil" if default.blank?
	interpret %{tr[
		td[code[#{m_name}] #[s_#{m_name.gsub(/\./, '_').gsub(/\*/,'')}]]
		td[txt[#{m_value}]]
		td[
			code[=
#{default}
			=]
		]
	]}
end

macro :out_cfg do
	setting = param(0)
	snippet = "&[o_#{setting.gsub(/^.+?\./, '')}]"
	interpret %{ref_config[output.#{setting}|
#{snippet}
	]}
end

macro :config_table do
	interpret %{table[
			tr[
				th[Name]
				th[Description]
				th[Default]
			]
			#{value}
		]}
end

macro :class do
	if value.match /Glyph::/ then
		path = "Glyph/#{value.gsub /Glyph::/, ''}"
	else
		path = value
	end
	interpret %{=>[&[rubydoc]/#{path}|code[#{value}]]}
end


macro_alias :options => :parameters
macro_alias :attributes => :parameters
macro_alias '-p' => :ref_error
macro_alias '-a' => :ref_error
macro_alias '-o' => :option
