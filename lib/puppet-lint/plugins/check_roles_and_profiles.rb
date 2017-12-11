ROLE_EXPR = /^(::)?roles?\b/
PROFILE_EXPR = /^(::)?profiles?\b/

PuppetLint.new_check(:node_definition) do
  def node_indexes
    @node_indexes ||= PuppetLint::Data.definition_indexes(:NODE)
  end

  def next_string_token(token)
    loop do
      following_token = token.next_code_token
      break if following_token.nil?
      break if following_token.type == :NEWLINE

      if %i[STRING SSTRING NAME].include?(following_token.type)
        break following_token
      end
      token = following_token
    end
  end

  def check
    node_indexes.each do |node|
      role_declarations = 0

      node[:tokens].each do |token|
        # this check only cares about declared classes, via function or
        # resource-like declaration, other lines are ignored
        next unless %i[NAME FUNCTION_NAME CLASS].include?(token.type) &&
                    %w[include contain require class].include?(token.value)

        class_name = next_string_token(token)
        if !class_name.nil? && class_name.value.match(ROLE_EXPR)
          role_declarations += 1
        else
          notify :warning,
                 :message => 'expected role declaration',
                 :line    => token.line,
                 :column  => token.column,
                 :token   => token
          next
        end

        next unless role_declarations > 1
        notify :warning,
               :message => 'expected only one role declaration',
               :line    => token.line,
               :column  => token.column,
               :token   => token
      end
    end
  end
end

PuppetLint.new_check(:roles_class_params) do
  def check
    class_indexes.select { |c| c[:name_token].value.match(ROLE_EXPR) }.each do |klass|
      next if klass[:param_tokens].nil?
      klass[:param_tokens].select { |t| t.type == :VARIABLE }.each do |token|
        notify :warning,
               :message => 'expected no class parameters',
               :line    => token.line,
               :column  => token.column
      end
    end
  end
end

PuppetLint.new_check(:roles_resource_declaration) do
  def check
    class_indexes.select {|c| c[:name_token].value.match(ROLE_EXPR)}.each do |klass|
      resource_indexes.select { |r| r[:start] > klass[:start] and r[:end] < klass[:end] }.each do |resource|
        if resource[:type].type != :CLASS ||
           !resource[:type].next_code_token.next_code_token.value.match(PROFILE_EXPR)
          notify :warning, {
            :message => 'expected no resource declaration',
            :line    => resource[:type].line,
            :column  => resource[:type].column,
          }
        end 
      end
      tokens[klass[:start]..klass[:end]].select { |t| t.value == 'include' }.each do |token|
        if !token.next_code_token.value.match(PROFILE_EXPR)
          notify :warning, {
            :message => 'expected no resource declaration',
            :line    => token.line,
            :column  => token.column,
          }
        end
      end
    end
  end
end

