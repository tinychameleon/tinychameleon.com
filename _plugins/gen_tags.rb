module Jekyll
  class TagIndexPage < Page
    def initialize(site, base, prefix, tag, posts)
      @site = site
      @base = base
      @dir = "#{prefix}/tag/#{tag}"
      @name = 'index.html'

      self.process(@name)
      self.read_yaml("#{base}/_layouts", 'tags.html')
      self.data['title'] = "Tag: #{tag}"
      self.data['posts'] = posts
    end
  end

  class TagIndexPageGenerator < Generator
    safe true
    priority :lowest

    def generate(site)
      prefix = directory_prefix(site)
      inject_tag_data(site.posts, prefix)
      posts_by_tag(site.posts).each do |tag, posts|
        site.pages << TagIndexPage.new(site, site.source, prefix, tag, posts)
      end
    end

    def directory_prefix(site)
      permalink = site.config.dig('collections', 'posts', 'permalink') or site.config.permalink
      return '' if permalink.nil?
      prefix = permalink.split(':title')[0]
      prefix = prefix[0...-1] if prefix[-1] == '/'
      prefix
    end

    def posts_by_tag(posts)
      hash = Hash.new { |h, k| h[k] = [] }
      posts.docs.each do |p|
        p.data['tags'].each { |t| hash[t] << p }
      end
      hash
    end

    def inject_tag_data(posts, prefix)
      memo = {}
      posts.docs.each do |p|
        p.data['tag_data'] = p.data['tags'].map do |t|
          if memo.has_key? t
            memo[t]
          else
            memo[t] = {'url' => "#{prefix}/tag/#{t}/", 'tag' => t}
          end
        end
      end
    end
  end
end
