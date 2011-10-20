package StatisticsCollector::TemplateBlocks;
use strict;
use warnings;
use Catalyst::View::ByCode::Renderer ':default';

block mod {
    my $class = attr('class');
    my $id = attr('id');
    
    div.mod {
        class "+$class" if $class;
        id $id if $id;
        
        b.top     { b.tl; b.tr; };
        div.inner { block_content; };
        b.bottom  { b.bl; b.br; };
    };
};

1;
