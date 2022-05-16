import sys
import argparse

import plotly.graph_objects as go
import plotly.io as pio

import pandas as pd

parser = argparse.ArgumentParser(description="Generate line graph of cumulative read counts")
parser.add_argument('-i', '--input', help="input file")
parser.add_argument('-o', '--output', help="output file")
opts = parser.parse_args(sys.argv[1:])

df = pd.read_csv(opts.input, sep="\t")
df['cumulative'] = df['count'].cumsum()

fig = go.Figure([go.Scatter(x=df['month'], y=df['cumulative'], mode='lines')])
fig.update_layout(width=1500, height=800, plot_bgcolor='rgba(0,0,0,0)')
fig.update_xaxes(showline=False)
fig.update_yaxes(showline=True, gridcolor='Grey', zeroline=True, zerolinecolor='Black')
# fig.show()
pio.write_image(fig, opts.output)
