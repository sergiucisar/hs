    if kind == 'ConfigMap' && cluster != 'eu-demo'
      config_keys = document['data'].keys.map(&:downcase)
      config_keys.zip(config_keys.sort).each do |unsorted_key, sorted_key|
        next if unsorted_key == sorted_key

        fail "ConfigMap key '#{unsorted_key.upcase}' is out of order (name = #{name})"
        break # Avoid adding more errors since the rest might just be off by one
      end
