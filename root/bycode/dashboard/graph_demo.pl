#
# simple graph demo
#
sub css { 
    print RAW <<CSS;

.graph {
    position: relative;
    width: 600px;
    height: 400px;
    
    background-color: #6060ff; /* eventually gradient #6060ff(tl) ---> #60ff60(br) */
    
    font-family: Helvetica, Arial, sans-serif;
    font-size: 12px; /* !!! */
    font-weight: normal;
    color: #000000;
}

.graph .head {
    position: absolute;
    top: 2%;
    left: 6%;
    right: 3%;

    font-size: 20px;
    font-weight: bold;
    text-align: center;
}

.graph .drawing { /* the whole drawing area */
    position: absolute;
    top: 4em;   /* 9%; */
    left: 6%;
    bottom: 2em; /* 5%; */
    right: 3%;
    /* border: 1px dotted #ff0000; */
    background-color: #ffffff;
}

.graph .ytick { /* a horizontal line with an attached description */
    position: absolute;
    top: 42%; /* must be overwritten by a style attribute */
    left: 0%;
    width: 100%;
    height: 0;
    
    border-top: 1px dashed #cccccc;
}

.graph .ytick .desc { /* the test left of the tick */
    position: absolute;
    right: 101%;
    width: 5%;
    top: 0;
    height: auto;
    margin-top: -0.5em;
    
    text-align: right;
}

.graph .xtick { /* a short tick line along the x-axis */
    position: absolute;
    left: 42%; /* must be overwritten by a style attribute */
    top: 100%;
    width: 0;
    height: 1em;
    
    margin-top: -0.5em;
    border-left: 1px solid #000000;
}

.graph .xtick .desc { /* the test left of the tick */
    position: absolute;
    top: 1em;
    left: -50em;
    width: 100em;
    height: 2em;

    text-align: center;
    overflow: hidden;
}

.graph .bars {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    clip: rect(0 auto auto 0);
}

.graph .bar {
    position: absolute;
    /* measures must be specified individually */
    background-color: #07ff07;
    
    width: 3%;     /* may be changed */
    height: 100%;  /* will get clipped, so don't worry! */
}

.graph .bar.max {
    background-color: #ffc0c0;
}

CSS
}

template {
    style { css };

    mod.topic {
        div.hd.section.phm {
            h3 { 'Graph Demo' }
        };
        div.bd {

            br;
            br;
            br;

            div.graph {
                div.head { 'Erlangen / Aussen / Temperatur' };
                
                div.drawing {
                    div.bars {
                        div.bar.max(style => {left => '5.5%', top => '70%'});
                        div.bar.min(style => {left => '5.5%', top => '73%'});

                        div.bar.max(style => {left => '9.5%', top => '40%'});
                        div.bar.min(style => {left => '9.5%', top => '53%'});
                        
                        div.bar.max(style => {left => '13.5%', top => '30%'});
                        div.bar.min(style => {left => '13.5%', top => '53%'});

                        div.bar.max(style => {left => '17.5%', top => '70%'});
                        div.bar.min(style => {left => '17.5%', top => '73%'});

                        div.bar.max(style => {left => '21.5%', top => '40%'});
                        div.bar.min(style => {left => '21.5%', top => '53%'});
                        
                        div.bar.max(style => {left => '25.5%', top => '30%'});
                        div.bar.min(style => {left => '25.5%', top => '53%'});

                        div.bar.max(style => {left => '29.5%', top => '70%'});
                        div.bar.min(style => {left => '29.5%', top => '73%'});

                        div.bar.max(style => {left => '33.5%', top => '40%'});
                        div.bar.min(style => {left => '33.5%', top => '53%'});
                        
                        div.bar.max(style => {left => '37.5%', top => '30%'});
                        div.bar.min(style => {left => '37.5%', top => '53%'});

                        div.bar.max(style => {left => '41.5%', top => '70%'});
                        div.bar.min(style => {left => '41.5%', top => '73%'});

                        div.bar.max(style => {left => '45.5%', top => '40%'});
                        div.bar.min(style => {left => '45.5%', top => '53%'});
                        
                        div.bar.max(style => {left => '49.5%', top => '30%'});
                        div.bar.min(style => {left => '49.5%', top => '53%'});

                        div.bar.max(style => {left => '53.5%', top => '70%'});
                        div.bar.min(style => {left => '53.5%', top => '73%'});

                        div.bar.max(style => {left => '57.5%', top => '40%'});
                        div.bar.min(style => {left => '57.5%', top => '53%'});
                        
                        div.bar.max(style => {left => '61.5%', top => '30%'});
                        div.bar.min(style => {left => '61.5%', top => '53%'});

                    };
                    
                    # ticks along the x-axis and description
                    div.xtick(style => {left =>  '7%'}) { div.desc { 42 } };
                    div.xtick(style => {left => '21%'}) { div.desc { 52 } };
                    div.xtick(style => {left => '35%'}) { div.desc { 62 } };
                    
                    # horizontal lines and scale
                    div.ytick(style => {top =>   '0%'}) { div.desc { 20 } };
                    div.ytick(style => {top =>  '25%'}) { div.desc { 15 } };
                    div.ytick(style => {top =>  '50%'}) { div.desc { 10 } };
                    div.ytick(style => {top =>  '75%'}) { div.desc {  5 } };
                    div.ytick(style => {top => '100%'}) { div.desc {  0 } };
                };
            };


            br;
            br;
            br;


        };
    };
};
