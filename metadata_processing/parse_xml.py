# Parsear xml para obtener tsv con las runs

import xml.etree.ElementTree as ET
import pandas as pd

def parse_xml(fich_xml:str = None):
    if fich_xml is not None:
        tree = ET.parse(fich_xml)
        root = tree.getroot()
        data = []

        for sample in root.findall('SAMPLE'):
            accession = sample.attrib.get('accession')
            title_elem = sample.find('TITLE')
            title = title_elem.text.replace(" ", "") if title_elem is not None else None
            data.append({'accession': accession, 'title': title})

        data_frame_xml = pd.DataFrame(data)
        data_frame_xml.to_csv('DRA001281.tsv', sep='\t', encoding='utf-8')
        print('Fichero tsv con datos de xml creado.')
        return None


def merge_tsvs(fich_tsv_xml:str = None, fich_emilia:str = None, fich_metadata:str = None):
    df_xml = pd.read_csv(fich_tsv_xml, sep='\t')
    print('xml leido.')

    df_emilia = pd.read_csv(fich_emilia, sep='\t')
    print('datos Emilia leidos.')

    # Unir xml con emilia
    df_xml_emilia = df_emilia[df_emilia.iloc[:, 0].isin(df_xml['title'])]
    df_xml_emilia.columns.values[0] = 'title'
    
    df_merged_xml_emilia = pd.merge(df_xml_emilia, df_xml, on='title', how='inner')
    df_merged_xml_emilia.to_csv('xml_emilia_merged.tsv', sep='\t', encoding='utf-8')
    print('Fichero fusionado (xml con emilia) creado.')
    return None


    


if __name__ == '__main__':
    #xml_to_tsv = parse_xml('DRA001281.sample.xml')
    #merge_tsvs('DRA001281.tsv', 'muestras.tsv')
    None